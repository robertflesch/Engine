/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.server.Network;
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
	
	private var _vmi:ModelInfo;
	private var _vmm:ModelMetadata;
	
	public function ModelMakerImport( $ii:InstanceInfo, $prompt:Boolean = true, $parentModelGuid:String = null ) {
		super( $ii, false, $parentModelGuid );
		Log.out( "ModelMakerImport - ii: " + _ii.toString() );
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retrivedInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retrivedInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		

		if ( $prompt )
			new WindowModelMetadata( _ii.modelGuid, WindowModelMetadata.TYPE_IMPORT );
		else {
			_vmm = new ModelMetadata( _ii.modelGuid );
			_vmm.name = _ii.modelGuid;
			_vmm.description = _ii.modelGuid + "-IMPORTED";
			_vmm.creator = Network.userId;
			_vmm.owner = Network.userId;
			_vmm.createdDate = new Date();
			_vmm.modifiedDate = new Date();
			attemptMake();
		}
	}
	
	private function retrivedMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			_vmm = $mme.vmm;
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
			markComplete(false);
		}
	}
	
	private function retrivedInfo( $mie:ModelInfoEvent ):void {
		if ( _ii.modelGuid == $mie.modelGuid ) {
			_vmi = $mie.vmi;
			attemptMake();
		}
	}
	
	private function failedInfo( $mie:ModelInfoEvent ):void {
		if ( _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelInfoEvent: " + $mie.toString(), Log.WARN );
			markComplete(false);
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null != _vmd && null != _vmm ) {
			
			var $ba:ByteArray = _vmd.ba;
			
			var versionInfo:Object = modelMetaInfoRead( $ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.test - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes, even though we are using the data from the modelInfo file
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
			// reset the file name that it was loaded from and assign a new guid
			_ii.modelGuid = _vmm.modelGuid = _vmd.modelGuid = Globals.getUID();
			_vmi.fileName = "";
			
			var vm:* = instantiate( _ii, _vmi, _vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.fromByteArray( $ba );
			}
			Region.currentRegion.modelCache.add( vm );

			vm.data = _vmd;
			vm.complete = true;
			vm.changed = true;
			vm.save();
			vm.stateLock( true, 10000 );
			
			markComplete();
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, 0, Region.currentRegion.guid ) );
		}
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retrivedInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrivedInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrivedMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrivedMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
		
		LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _vmm.modelGuid ) );
		
		super.markComplete( $success );
	}
}	
}