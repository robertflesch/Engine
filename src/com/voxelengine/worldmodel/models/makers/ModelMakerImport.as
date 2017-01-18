/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
//import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.PermissionsBase;

import flash.geom.Vector3D;
import flash.utils.ByteArray;
import org.flashapi.swing.Alert;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.GUI.WindowModelMetadata;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;

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
	private var _vmTemp:VoxelModel;

	public function ModelMakerImport( $ii:InstanceInfo, $prompt:Boolean = true ) {
		// This should never happen in a release version, so dont worry about setting it to false when done
		_isImporting = true;
		_prompt = $prompt;
		super( $ii, false );
		Log.out( "ModelMakerImport - ii: " + ii.toString(), Log.WARN );
		retrieveBaseInfo();
	}

	override protected function retrieveBaseInfo():void {
		addListeners();	
		// Since this is the import, it uses the local file system rather then persistance
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );
	}
	
	// next get or generate the metadata
	override protected function attemptMake():void {
		Log.out( "ModelMakerImport - attemptMake: " + ii.toString() );
		if ( null != modelInfo && null == _modelMetadata ) {
			// The new guid is generated in the Window or in the hidden metadata creation
			if ( _prompt ) {
				Log.out( "ModelMakerImport - attemptMake: gathering metadata " + ii.toString() );
				ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, metadataFromUI );
				new WindowModelMetadata( ii, WindowModelMetadata.TYPE_IMPORT ); }
			else {
				Log.out( "ModelMakerImport - attemptMake: generating metadata " + ii.toString() );
				_modelMetadata = new ModelMetadata( ii.modelGuid );
				var newObj:Object = ModelMetadata.newObject()
				_modelMetadata.fromObjectImport( newObj );
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
			Log.out( "ModelMakerImport.metadataFromUI: " + ii.toString() );
			attemptMakeRetrieveParentModelInfo();
		}
	}

	private function attemptMakeRetrieveParentModelInfo():void {
		if ( parentModelGuid ) {
			Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - retrieveParentModelInfo " + ii.toString());
			retrieveParentModelInfo();
		}
		else {
			Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - completeMake " + ii.toString());
			completeMake();
		}
	}
	
	private function retrieveParentModelInfo():void {
		Log.out("ModelMakerImport.retrieveParentModelInfo: " + ii.toString());
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		addParentModelInfoListener();
		var _topMostModelGuid:String = ii.topmostModelGuid();
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _topMostModelGuid, null ) );

		function parentModelInfoResult($mie:ModelInfoEvent):void {
			if ( $mie.modelGuid == _topMostModelGuid ) {
				Log.out("ModelMakerImport.parentModelInfoResult: " + ii.toString());
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
	
	private function completeMake():void {
		Log.out("ModelMakerImport.completeMake: " + ii.toString());
		if ( null != modelInfo && null != _modelMetadata ) {

			_vmTemp = make();
			if ( _vmTemp ) {
				_vmTemp.stateLock( true, 10000 ); // Lock state so that it has time to load animations
                // this gets saved in the vm.save
				//_modelMetadata.save();
				if ( null == _vmTemp.instanceInfo.controllingModel ) {
					// Only do this for top level models.
					var lav:Vector3D = Player.player.instanceInfo.lookAtVector(500);
					var diffPos:Vector3D = Player.player.wsPositionGet().clone();
					diffPos = diffPos.add(lav);
					_vmTemp.instanceInfo.positionSet = diffPos;
				}
				addOxelDataCompleteListeners();
				_vmTemp.modelInfo.oxelLoadData();
			}
		}
		else
			Log.out( "ModelMakerImport.completeMake - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );

		function oxelReady( $ode:OxelDataEvent):void {
			Log.out( "ModelMakerImport.oxelReady - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid ) {
				removeOxelDataCompleteListeners();
				modelInfo.assignOxelDataToModelInfo( $ode.oxelData );
				markComplete( true, _vmTemp );
			}
			else
				Log.out( "ModelMakerImport.oxelReady - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}

		function oxelFailedToLoad( $ode:OxelDataEvent):void {
			if ( modelInfo.guid == $ode.modelGuid || modelInfo.altGuid == $ode.modelGuid  ) {
				removeOxelDataCompleteListeners();
				markComplete( false, _vmTemp );
			}
			else
				Log.out( "ModelMakerImport.oxelFailedToLoad - modelInfo.guid != $ode.modelGuid - modelInfo.guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid , Log.WARN );
		}

		function addOxelDataCompleteListeners():void {
			OxelDataEvent.addListener( ModelBaseEvent.ADDED, oxelReady );
			OxelDataEvent.addListener( OxelDataEvent.OXEL_FAILED, oxelFailedToLoad );
		}

		function removeOxelDataCompleteListeners():void {
			OxelDataEvent.removeListener( ModelBaseEvent.ADDED, oxelReady );
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FAILED, oxelFailedToLoad );
		}
	}

	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		if ( false == $success && modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" ) {
			Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.WARN );

			(new Alert( "ERROR importing model" )).display();
			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
			return;
		} else {
			Log.out("ModelMakerImport.completeMake - needed info found: " + ii.toString());
			if ( !Globals.isGuid( _modelMetadata.guid ) )
				_modelMetadata.guid = Globals.getUID();

			modelInfo.guid = _modelMetadata.guid;
			ii.modelGuid 	= _modelMetadata.guid;

			ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
			ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
			_vmTemp.complete = true;

			modelInfo.changed = true;
			modelInfo.data.changed = true;
			_modelMetadata.changed = true;
			_vmTemp.save();
			Region.currentRegion.modelCache.add( _vmTemp );
		}


		if ( null == _vmTemp.instanceInfo.controllingModel ) {
			Region.currentRegion.save();
		}
		super.markComplete( $success, _vmTemp );
		// how are sub models handled?
		//_isImporting = false;
		_vmTemp = null;

	}
}	
}