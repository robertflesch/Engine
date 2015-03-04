/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.GUI.WindowModelMetadata;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelData;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.Region;
import flash.utils.ByteArray;
import org.flashapi.swing.Alert;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerImport {
	
	private var _ii:InstanceInfo;
	private var _vmd:ModelData;
	private var _vmi:ModelInfo;
	private var _vmm:ModelMetadata;
	
	public function ModelMakerImport( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMakerImport - ii: " + _ii.toString() );
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, _ii.guid, null ) );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, _ii.guid, null, false ) );		

		new WindowModelMetadata( _ii.guid, WindowModelMetadata.TYPE_IMPORT );		
	}
	
	private function retriveMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.guid == $mme.guid ) {
			_vmm = $mme.vmm;
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent ):void {
		if ( _ii.guid == $mme.guid ) {
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
			markComplete();
		}
	}
	
	private function retriveInfo( $mie:ModelInfoEvent ):void {
		if ( _ii.guid == $mie.guid ) {
			_vmi = $mie.vmi;
			attemptMake();
		}
	}
	
	private function failedInfo( $mie:ModelInfoEvent ):void {
		if ( _ii.guid == $mie.guid ) {
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelInfoEvent: " + $mie.toString(), Log.WARN );
			markComplete();
		}
	}
	
	private function retriveData($mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			_vmd = $mde.vmd;
			attemptMake();
		}
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			Log.out( "ModelMaker.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
			(new Alert( "Failed to import model: " + _ii.guid + " data not found" ).display() );
			// TODO need some sort of shut down message for the WindowModelMetadata
			markComplete();
		}
	}
	
	// once they both have been retrived, we can make the object
	private function attemptMake():void {
		if ( null != _vmi && null != _vmd && null != _vmm ) {
			
			var $ba:ByteArray = _vmd.ba;
			
			try {  $ba.uncompress(); }
			catch (error:Error) { ; }
			$ba.position = 0;
			
			var versionInfo:Object = ModelLoader.modelMetaInfoRead( $ba );
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
			_ii.guid = _vmm.guid = _vmd.guid = Globals.getUID();
			_vmi.fileName = "";
			
			var vm:* = ModelLoader.instantiate( _ii, _vmi, _vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.fromByteArray( $ba );
			}

			vm.data = _vmd;
			vm.complete = true;
			vm.changed = true;
			vm.save();
			
			markComplete();
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, Region.currentRegion.guid ) );
		}
	}
	
	private function markComplete():void {
		
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, retriveMetadata );		
		
		Log.out( "ModelMakerImport.markComplete - ii: " + _ii );
	}
}	
}