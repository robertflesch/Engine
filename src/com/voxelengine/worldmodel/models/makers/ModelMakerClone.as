/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.OxelPersistance;
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.models.ModelMetadata
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.GrainCursorUtils;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;

import flash.geom.Vector3D;
import flash.utils.ByteArray;

import org.flashapi.swing.Alert;

import playerio.DatabaseObject;

/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerClone extends ModelMakerBase {
	
	private var _vmTemp:VoxelModel;
		
	public function ModelMakerClone( $vm:VoxelModel, $killOldModel:Boolean = true ) {
		var originalVM:VoxelModel = $vm;

		Log.out( "ModelMakerClone - clone model with instanceGuid: " + $vm.instanceInfo.instanceGuid  + "  modelGuid: " + $vm.instanceInfo.modelGuid );
		super( originalVM.instanceInfo.clone(), false );
		ii.modelGuid = Globals.getUID();
		Log.out( "ModelMakerClone - clone model with NEW instanceGuid: " + ii.instanceGuid  + "  NEW modelGuid: " + ii.modelGuid );
		if ( $killOldModel ) {
			originalVM.dead = true;
		} else {
			var size:int = GrainCursor.two_to_the_g( $vm.modelInfo.oxelPersistance.oxel.gc.grain );
			var offset:Vector3D = new Vector3D(1,1,1);
			offset.scaleBy(size);
			var v:Vector3D = ii.positionGet.clone();
			v = v.add( offset );
			ii.positionSetComp( v.x, v.y, v.z  );
		}
		Log.out( "ModelMakerClone - ii: " + ii.toString() );

		addListeners();
		//oldWay( originalVM );
		newWay( originalVM );
	}

	private function newWay( $originalVM:VoxelModel ):void {
		// This gives me two new objects that have not been saved.
		_modelMetadata = $originalVM.metadata.cloneNew( ii.modelGuid );
		_modelInfo = $originalVM.modelInfo.cloneNew( ii.modelGuid );
		attemptMakeRetrieveParentModelInfo();
	}

/*
	private function oldWay( $originalVM:VoxelModel ):void {
		// this causes it to generate a ModelBaseEvent.ADDED event
		$originalVM.modelInfo.clone( ii.modelGuid );
		$originalVM.metadata.clone( ii.modelGuid );
		attemptMakeRetrieveParentModelInfo();

	}

	override protected function addListeners():void {
		super.addListeners()
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );
	}

	protected function removeListeners():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrivedMetadata );
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrivedMetadata );
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );
	}

	private function retrivedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			removeListeners();
			_modelMetadata = $mme.modelMetadata;
			//Log.out( "ModelMaker.retrivedMetadata - metadata: " + _modelMetadata.toString() )
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			removeListeners();
			markComplete(false);
		}
	}
	
	////////////////////////////////////////////
	// next get or generate the metadata
	override protected function attemptMake():void {
		// ignore for these type of maker.
	}
*/
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

	private var waitForChildren:Boolean;
	private function completeMake():void {
		//Log.out("ModelMakerClone.completeMake: " + ii.toString());
		if ( null != modelInfo && null != _modelMetadata ) {

			_vmTemp = make();
			if ( _vmTemp ) {
				_vmTemp.stateLock( true, 10000 ); // Lock state so that it has time to load animations
				// Since I already HAVE the oxel, I don't need to add it?
				// So just listen for ready event, unlike importer
				addOxelReadyDataCompleteListeners();
				modelInfo.oxelLoadData();
				if ( false == modelInfo.childrenLoaded ){ // its true if they are loaded or the model has no children.
					waitForChildren = true;
					ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				}
			}
		}
//		else
//			Log.out( "ModelMakerClone.completeMake - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );

		function childrenAllReady( $ode:ModelLoadingEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) {
				Log.out( "ModelMakerClone.allChildrenReady - modelMetadata.description: " + _modelMetadata.description, Log.WARN );
				ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				markComplete( true, _vmTemp );
			}
		}

		function oxelReady( $ode:OxelDataEvent):void {
			if ( modelInfo && ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) ) {
				removeOxelReadyDataCompleteListeners();
				Log.out( "ModelMakerClone.oxelReady - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
				if ( false == waitForChildren )
					markComplete(true, _vmTemp);
			}
//			else
//				Log.out( "ModelMakerClone.oxelReady - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}

		function oxelReadyFailedToLoad( $ode:OxelDataEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid  ) {
				removeOxelReadyDataCompleteListeners();
				markComplete( false, _vmTemp );
			}
//			else
//				Log.out( "ModelMakerClone.oxelReadyFailedToLoad - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}


		function addOxelReadyDataCompleteListeners():void {
			OxelDataEvent.addListener( OxelDataEvent.OXEL_READY, oxelReady );
			OxelDataEvent.addListener( OxelDataEvent.OXEL_FAILED, oxelReadyFailedToLoad );
		}

		function removeOxelReadyDataCompleteListeners():void {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_READY, oxelReady );
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FAILED, oxelReadyFailedToLoad );
		}
	}

	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		if ( false == $success && modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" ) {
			// Are these needed?
			ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
			ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
			_vmTemp.complete = true;

			modelInfo.changed = true;
			modelInfo.oxelPersistance.changed = true;
			_modelMetadata.changed = true;
			_vmTemp.save();

			if ( null == _vmTemp.instanceInfo.controllingModel ) {
				// Only do this for top level models.
				var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.lookAtVector(500);
				var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet().clone();
				diffPos = diffPos.add(lav);
				_vmTemp.instanceInfo.positionSet = diffPos;
				//Region.currentRegion.modelCache.add( _vmTemp );
				RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null );
			}
			RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, _vmTemp );
			Log.out("ModelMakerClone.completeMake - needed info found: " + _modelMetadata.description );
		} else {
			Log.out( "ModelMakerClone.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.WARN );

			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
		}

		super.markComplete( $success, _vmTemp );
		// how are sub models handled?
		//_isImporting = false;
		_vmTemp = null;

	}
	
	///////////////////////////////////////////
}	
}