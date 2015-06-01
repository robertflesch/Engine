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
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
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
		Log.out( "ModelMakerImport - ii: " + _ii.toString() );
		retrieveBaseInfo();
	}

	override protected function retrieveBaseInfo():void {
		super.retrieveBaseInfo();
		addListeners();
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		
	}
	
	private function addListeners():void {
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
	
	}
	
	private function retriveMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			removeListeners();
			_vmm = $mme.vmm;
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			removeListeners();
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
			markComplete(false);
		}
	}
	
	private function removeListeners():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null == _vmm ) {
			if ( _prompt )
				new WindowModelMetadata( _ii, WindowModelMetadata.TYPE_IMPORT );
			else {
				_vmm = new ModelMetadata( _ii.modelGuid );
				if ( _parentModelGuid )
					_vmm.parentModelGuid = _parentModelGuid;
				_vmm.name = _ii.modelGuid;
				_vmm.owner = Network.userId;
				_vmm.modifiedDate = new Date();
			}
		}
		
			
		if ( null != _vmi && null != _vmm ) {
			
			_ii.modelGuid = _vmm.guid = Globals.getUID();
			_vmi.fileName = "";
			
			var vm:* = make()
			if ( vm ) {
				vm.stateLock( true, 10000 );
				vm.complete = true;
				vm.changed = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			
			markComplete();
		}
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		if ( false == $success && _vmi && _vmi.boimeHas() ) {
			Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + _vmi.biomes.toString(), Log.WARN );
			return;
		}
		removeListeners();	
		super.markComplete( $success );
	}
}	
}