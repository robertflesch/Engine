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
		Log.out( "ModelMakerImport - ii: " + _ii.toString() );
		retrieveBaseInfo();
	}

	override protected function retrieveBaseInfo():void {
		addListeners();	
		// Since this is the import, it used the local file system rather then persistance
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );	
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null == _vmm ) {
			if ( _prompt ) {
				ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, metadataGenerated );
				new WindowModelMetadata( _ii, WindowModelMetadata.TYPE_IMPORT );
			}
			else {
				_vmm = new ModelMetadata( _ii.modelGuid );
				if ( _parentModelGuid )
					_vmm.parentModelGuid = _parentModelGuid;
				_vmm.name = _ii.modelGuid;
				_vmm.owner = Network.userId;
				_vmm.modifiedDate = new Date();
			}
		}
		completeMake();
	}
	
	private function completeMake():void {
		if ( null != _vmi && null != _vmm ) {
			
			_ii.modelGuid = _vmi.guid = _vmm.guid = Globals.getUID();
			_vmi.fileName = "";
			
			var vm:* = make()
			if ( vm ) {
				vm.stateLock( true, 10000 ); // Lock state so that is had time to load animations
				vm.changed = true;
//				vm.complete = true;
				_vmi.changed = true;
				_vmm.changed = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			
			markComplete( true, vm );
		}
	}
	
	private function metadataGenerated( $mme:ModelMetadataEvent):void 
	{
		if ( $mme.modelGuid == _vmi.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.GENERATION, metadataGenerated );
			_vmm = $mme.vmm;
			completeMake();
		}
	}
	
	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		if ( false == $success && _vmi && _vmi.boimeHas() ) {
			Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + _vmi.biomes.toString(), Log.WARN );
			return;
		}
		super.markComplete( $success, $vm );
	}
}	
}