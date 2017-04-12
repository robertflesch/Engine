/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import flash.geom.Vector3D;

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.oxel.GrainCursor;

public class ModelMakerClone extends ModelMakerBase {
	
	public function ModelMakerClone( $vm:VoxelModel, $killOldModel:Boolean = true ) {
		super($vm.instanceInfo.clone(), false);
		Log.out("ModelMakerClone - clone model with instanceGuid: " + $vm.instanceInfo.instanceGuid + "  modelGuid: " + $vm.instanceInfo.modelGuid);
		ii.modelGuid = Globals.getUID();
		Log.out("ModelMakerClone - clone model with NEW instanceGuid: " + ii.instanceGuid + "  NEW modelGuid: " + ii.modelGuid);
		if ($killOldModel) {
			$vm.dead = true;
		} else {
			// Only do this for top level models.
			if ( null == $vm.instanceInfo.controllingModel ) {
				var size:int = GrainCursor.two_to_the_g( $vm.modelInfo.oxelPersistence.oxel.gc.grain );
				var v:Vector3D = ii.positionGet.clone();
				ii.positionSetComp(v.x + size / 4, v.y + size / 4, v.z + size / 4);
			}
		}

		// This gives me two new objects that have not been saved.
		_modelMetadata = $vm.metadata.cloneNew( ii.modelGuid );
		_modelInfo = $vm.modelInfo.cloneNew( ii.modelGuid );
		attemptMakeRetrieveParentModelInfo();
	}

	private function attemptMakeRetrieveParentModelInfo():void {
		if ( parentModelGuid )
			retrieveParentModelInfo();
		else
			completeMake();
	}

	private function retrieveParentModelInfo():void {
		//Log.out("ModelMakerClone.retrieveParentModelInfo: " + ii.toString());
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		addParentModelInfoListener();
		var _topMostModelGuid:String = ii.topmostModelGuid();
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _topMostModelGuid, null ) );

		function parentModelInfoResult($mie:ModelInfoEvent):void {
			if ( $mie.modelGuid == _topMostModelGuid ) {
				//Log.out("ModelMakerClone.parentModelInfoResult: " + ii.toString());
				removeParentModelInfoListener();
				var modelClass:String = $mie.vmi.modelClass;
				_modelMetadata.animationClass = AnimationCache.requestAnimationClass( modelClass );
				completeMake();
			}
		}

		function parentModelInfoResultFailed($mie:ModelInfoEvent):void {
			Log.out("ModelMakerClone.parentModelInfoResultFailed: " + ii.toString(), Log.ERROR);
			if ( $mie.modelGuid == modelInfo.guid ) {
				removeParentModelInfoListener();
				markComplete( false );
			}
		}

		function addParentModelInfoListener():void {
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, parentModelInfoResult );
			ModelInfoEvent.addListener( ModelBaseEvent.ADDED, parentModelInfoResult );
			ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		}

		function removeParentModelInfoListener():void {
			ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, parentModelInfoResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, parentModelInfoResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed);
		}
	}

	private function completeMake():void {
		//Log.out("ModelMakerClone.completeMake: " + ii.toString());
		if ( null != modelInfo && null != _modelMetadata ) {

			_vm = make();
			if ( _vm ) {
				_vm.stateLock( true, 10000 ); // Lock state so that it has time to load animations
				new OxelLoadAndBuildManager( modelInfo.guid, modelInfo.oxelPersistence, false );
				if ( false == modelInfo.childrenLoaded ){ // its true if they are loaded or the model has no children.
					ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				} else
					markComplete( true );
			} else {
				markComplete(false);
			}
		}
		else
			Log.out( "ModelMakerClone.completeMake - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );

		function childrenAllReady( $ode:ModelLoadingEvent):void {
			if ( modelInfo.guid == $ode.modelGuid  ) {
				Log.out( "ModelMakerClone.allChildrenReady - modelMetadata.description: " + _modelMetadata.description, Log.WARN );
				ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				markComplete( true );
			}
		}
		function childLoadFailed():void {
			/*
			TODO How to prepare for this?
			Look at modelLoading event, and see if the guid is one of our children?
			 */
		}
	}

	override protected function markComplete( $success:Boolean ):void {
		if ( true == $success ) {
			ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
			ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
			_vm.complete = true;

			modelInfo.brandChildren();
			modelInfo.changed = true;
			_modelMetadata.changed = true;
			_vm.save();
		} else {
			if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
				Log.out( "ModelMakerClone.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.ERROR );
			else if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName )
				Log.out( "ModelMakerClone.markComplete - Failed import, Failed to load from IVM : " + modelInfo.guid, Log.ERROR );
			else
				Log.out( "ModelMakerClone.markComplete - Unknown error causing failure : " + ii.modelGuid, Log.ERROR );

			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
			ModelMetadataEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
		}

		Log.out("ModelMakerClone.completeMake - needed info found: " + _modelMetadata.description );
		super.markComplete( $success );
	}
}
}