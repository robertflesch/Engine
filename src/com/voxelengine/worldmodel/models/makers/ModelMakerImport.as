/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;

import flash.geom.Vector3D;
import org.flashapi.swing.Alert;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.GUI.WindowModelMetadata;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerImport extends ModelMakerBase {
	
	static private var _isImporting:Boolean;
	static public function get isImporting():Boolean { return _isImporting; }
	
	private var _prompt:Boolean;

	public function ModelMakerImport( $ii:InstanceInfo, $prompt:Boolean = true ) {
		// This should never happen in a release version, so dont worry about setting it to false when done
		_isImporting = true;
		_prompt = $prompt;
		super( $ii, false );
		Log.out( "ModelMakerImport - ii: " + ii.toString(), Log.DEBUG );
		retrieveBaseInfo();
	}

	override protected function retrieveBaseInfo():void {
		addListeners();	
		// Since this is the import, it uses the local file system rather then persistance
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );
	}
	
	// next get or generate the metadata
	override protected function attemptMake():void {
		//Log.out( "ModelMakerImport - attemptMake: " + ii.toString() );
		if ( null != modelInfo && null == _modelMetadata ) {
			// The new guid is generated in the Window or in the hidden metadata creation
			if ( _prompt ) {
				//Log.out( "ModelMakerImport - attemptMake: gathering metadata " + ii.toString() );
				ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, metadataFromUI );
				new WindowModelMetadata( ii, WindowModelMetadata.TYPE_IMPORT ); }
			else {
				//Log.out( "ModelMakerImport - attemptMake: generating metadata " + ii.toString() );
				_modelMetadata = new ModelMetadata( ii.modelGuid );
				_modelMetadata.description = ii.modelGuid + " - Imported";
				_modelMetadata.name = ii.modelGuid;
				_modelMetadata.owner = Network.userId;
				attemptMakeRetrieveParentModelInfo(); }
		}
		else if ( null == modelInfo && null == _modelMetadata )
			Log.out( "ModelMakerImport - attemptMake: null == modelInfo && null == _modelMetadata " + ii.toString() );
		else if ( null == modelInfo )
			Log.out( "ModelMakerImport - attemptMake: null == modelInfo " + ii.toString() );
		else
			Log.out( "ModelMakerImport - attemptMake: INVALID CONDITION" + ii.toString(), Log.ERROR );

	}
	
	private function metadataFromUI( $mme:ModelMetadataEvent):void {
		if ( $mme.modelGuid == modelInfo.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.GENERATION, metadataFromUI );
			_modelMetadata = $mme.modelMetadata;
			// Now check if this has a parent model, if so, get the animation class from the parent.
			//Log.out( "ModelMakerImport.metadataFromUI: " + ii.toString() );
			attemptMakeRetrieveParentModelInfo();
		}
	}

	private function attemptMakeRetrieveParentModelInfo():void {
		if ( parentModelGuid ) {
			//Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - retrieveParentModelInfo " + ii.toString());
			retrieveParentModelInfo();
		}
		else {
			//Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - completeMake " + ii.toString());
			if ( modelInfo.modelClass ) {
				var modelClass:String = modelInfo.modelClass;
				_modelMetadata.animationClass = AnimationCache.requestAnimationClass(modelClass);
			} else
				_modelMetadata.animationClass = AnimationCache.MODEL_UNKNOWN;

			completeMake();
		}
	}
	
	private function retrieveParentModelInfo():void {
		//Log.out("ModelMakerImport.retrieveParentModelInfo: " + ii.toString());
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		addParentModelInfoListener();
		var _topMostModelGuid:String = ii.topmostModelGuid();
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _topMostModelGuid, null ) );

		function parentModelInfoResult($mie:ModelInfoEvent):void {
			if ( $mie.modelGuid == _topMostModelGuid ) {
				//Log.out("ModelMakerImport.parentModelInfoResult: " + ii.toString());
				removeParentModelInfoListener();
				var modelClass:String = $mie.vmi.modelClass;
				_modelMetadata.animationClass = AnimationCache.requestAnimationClass( modelClass );
				completeMake();
			}
		}

		function parentModelInfoResultFailed($mie:ModelInfoEvent):void {
			Log.out("ModelMakerImport.parentModelInfoResultFailed: " + ii.toString(), Log.ERROR);
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
		//Log.out("ModelMakerImport.completeMake: " + ii.toString());
		if ( null != modelInfo && null != _modelMetadata ) {

			_vm = make();
			if ( _vm ) {
				_vm.stateLock( true, 10000 ); // Lock state so that it has time to load animations
				OxelDataEvent.addListener( ModelBaseEvent.ADDED, oxelAdded );
				OxelDataEvent.addListener( ModelBaseEvent.GENERATION, oxelAdded );
				modelInfo.oxelLoadData();
				if ( false == modelInfo.childrenLoaded ){ // its true if they are loaded or the model has no children.
					waitForChildren = true;
					ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				}
			}
		}
//		else
//			Log.out( "ModelMakerImport.completeMake - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );

		function childrenAllReady( $ode:ModelLoadingEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) {
				Log.out( "ModelMakerImport.allChildrenReady - modelMetadata.description: " + _modelMetadata.description, Log.WARN );
				ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				markComplete( true );
			}
		}

		function oxelAdded( $ode:OxelDataEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) {
				//Log.out( "ModelMakerImport.oxelReady - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );
				OxelDataEvent.removeListener( ModelBaseEvent.ADDED, oxelAdded );
				OxelDataEvent.removeListener( ModelBaseEvent.GENERATION, oxelAdded );
				addOxelReadyDataCompleteListeners();
				modelInfo.assignOxelDataToModelInfo( $ode.oxelData );
			}
//			else
//				Log.out( "ModelMakerImport.oxelReady - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}

		function oxelReady( $ode:OxelDataEvent):void {
			if ( modelInfo && ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) ) {
				removeOxelReadyDataCompleteListeners();
				Log.out( "ModelMakerImport.oxelReady - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );

				VisitorFunctions.resetScaling( $ode.oxelData.oxel );
				//Oxel.rebuild( $ode.oxelData.oxel );

				if ( false == waitForChildren )
					markComplete(true );
			}
//			else
//				Log.out( "ModelMakerImport.oxelReady - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}

		function oxelReadyFailedToLoad( $ode:OxelDataEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid  ) {
				removeOxelReadyDataCompleteListeners();
				markComplete( false );
			}
//			else
//				Log.out( "ModelMakerImport.oxelReadyFailedToLoad - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
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



	override protected function markComplete( $success:Boolean ):void {
		if ( true == $success ) {
			if ( !Globals.isGuid( _modelMetadata.guid ) )
				_modelMetadata.guid = Globals.getUID();

			modelInfo.guid = _modelMetadata.guid;
			ii.modelGuid 	= _modelMetadata.guid;

			ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
			ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
			_vm.complete = true;

			modelInfo.brandChildren();
			modelInfo.changed = true;
			_modelMetadata.changed = true;
			_vm.save();

			if ( null == _vm.instanceInfo.controllingModel ) {
				// Only do this for top level models.
				var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.lookAtVector(500);
				var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet().clone();
				diffPos = diffPos.add(lav);
				_vm.instanceInfo.positionSet = diffPos;
			}

		} else {
			if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
				Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.ERROR );
			else if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName )
				Log.out( "ModelMakerImport.markComplete - Failed import, Failed to load from IVM : " + modelInfo.guid, Log.ERROR );
			else
				Log.out( "ModelMakerImport.markComplete - Unknown error causing failure : " + ii.modelGuid, Log.ERROR );

			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
			ModelMetadataEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
		}

		Log.out("ModelMakerImport.completeMake - needed info found: " + _modelMetadata.description );
		super.markComplete( $success );
		// how are sub models handled?
		//_isImporting = false;
	}
}	
}