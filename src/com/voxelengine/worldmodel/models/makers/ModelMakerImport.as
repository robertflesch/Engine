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
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;
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
	
	private var _prompt:Boolean;
	
	public function ModelMakerImport( $ii:InstanceInfo, $prompt:Boolean = true ) {
		_prompt = $prompt;
		super( $ii, false );
		Log.out( "ModelMakerImport - ii: " + ii.toString() );
		retrieveBaseInfo();
	}

	override protected function retrieveBaseInfo():void {
		addListeners();	
		// Since this is the import, it used the local file system rather then persistance
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );	
	}
	
	// next get or generate the metadata
	override protected function attemptMake():void {
		if ( null != _modelInfo && null == _modelMetadata ) {
			// The new guid is generated in the Window or in the hidden metadata creation
			if ( _prompt ) {
				ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, metadataFromUI );
				new WindowModelMetadata( ii, WindowModelMetadata.TYPE_IMPORT ); }
			else {
				_modelMetadata = new ModelMetadata( Globals.getUID() );
				_modelMetadata.name = ii.modelGuid;
				_modelMetadata.owner = Network.userId;
				_modelMetadata.modifiedDate = new Date();
				attemptMakeRetrieveParentModelInfo(); }
		}	
	}
	
	private function metadataFromUI( $mme:ModelMetadataEvent):void {
		if ( $mme.modelGuid == _modelInfo.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.GENERATION, metadataFromUI );
			_modelMetadata = $mme.modelMetadata;
			_modelMetadata.guid = Globals.getUID();
			attemptMakeRetrieveParentModelInfo(); 
		}
	}

	protected function attemptMakeRetrieveParentModelInfo():void {
		if ( parentModelGuid )
			retrieveParentModelInfo();
		else
			completeMake();
	}
	
	private function retrieveParentModelInfo():void {
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, parentModelInfoResult );
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, parentModelGuid, null ) );
	}
	
	private function parentModelInfoResult(e:ModelInfoEvent):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, parentModelInfoResult );
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		var modelClass:String = e.vmi.modelClass;
		_modelMetadata.animationClass = AnimationCache.requestAnimationClass( modelClass );
		completeMake();
	}
	
	private function parentModelInfoResultFailed(e:ModelInfoEvent):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, parentModelInfoResult );
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		markComplete( false );
	}
	
	private function completeMake():void {
		if ( null != _modelInfo && null != _modelMetadata ) {
			
			_modelInfo.guid = _modelMetadata.guid;
			ii.modelGuid 	= _modelMetadata.guid;
			_modelInfo.fileName = "";
			
			var vm:* = make()
			if ( vm ) {
				vm.stateLock( true, 10000 ); // Lock state so that is had time to load animations
				vm.changed = true;
//				vm.complete = true;
				_modelInfo.changed = true;
				_modelMetadata.changed = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			
			markComplete( true, vm );
		}
	}
	
	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		if ( false == $success && _modelInfo && _modelInfo.boimeHas() ) {
			Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + _modelInfo.biomes.toString(), Log.WARN );
			return;
		}
		super.markComplete( $success, $vm );
	}
}	
}