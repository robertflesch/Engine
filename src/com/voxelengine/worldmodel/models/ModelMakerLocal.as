/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.MetadataManager;
import com.voxelengine.worldmodel.models.VoxelModelData;
import com.voxelengine.worldmodel.models.ModelInfo;
import flash.utils.ByteArray;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerLocal {
	
	// keeps track of how many makers there currently are.
	static public var _makerCount:int;
	
	private var _ii:InstanceInfo;
	private var _vmd:VoxelModelData;
	private var _vmi:ModelInfo;
	
	public function ModelMakerLocal( $ii:InstanceInfo ) {
		_ii = $ii;
		ModelInfoEvent.addListener( ModelInfoEvent.ADDED, retriveInfo );		
		ModelDataEvent.addListener( ModelDataEvent.ADDED, retriveData );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelInfoEvent.REQUEST, _ii.guid, null ) );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.REQUEST, _ii.guid, null ) );		

		_makerCount++;
	}
	
	private function retriveInfo(e:ModelInfoEvent):void {
		if ( _ii.guid == e.guid ) {
			ModelInfoEvent.removeListener( ModelInfoEvent.ADDED, retriveInfo );
			_vmi = e.vmi;
			attemptMake();
		}
	}
	
	private function retriveData(e:ModelDataEvent):void  {
		if ( _ii.guid == e.guid ) {
			ModelDataEvent.removeListener( ModelDataEvent.ADDED, retriveData );		
			_vmd = e.vmd;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	private function attemptMake():void {
		if ( null != _vmi && null != _vmd ) {
			
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
			// read off that many bytes
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
			// create the modelInfo object from embedded metadata
			//modelInfoJson = decodeURI(modelInfoJson);
			//var jsonResult:Object = JSON.parse(modelInfoJson);
			//var mi:ModelInfo = new ModelInfo();
			//mi.initJSON( $vmm.guid, jsonResult );

			//if ( "" != controllingModelGuid ) {
				//var cvm:VoxelModel = Globals.getModelInstance( controllingModelGuid );
				//ii.controllingModel = cvm;
			//}
				
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.guid = _ii.guid;
			var vm:* = ModelLoader.instantiate( _ii, _vmi, vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.loadOxelFromByteArray( $ba );
			}

			vm.complete = true;
			
			
			_makerCount--;
		}
		
		if ( 0 == _makerCount )
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
	}
	
	/*
		static public function test( $ii:InstanceInfo, $ba:ByteArray ):VoxelModel {
				
			if ( null == $ba )
			{
				Log.out( "VoxelModel.test - Exception - NO in byte array: " + $ii.guid, Log.ERROR );
				return null;
			}
			$ba.position = 0;
			
			var versionInfo:Object = modelMetaInfoRead( $ba );
			if ( MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.test - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return null;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
			
			// create the modelInfo object from embedded metadata
			modelInfoJson = decodeURI(modelInfoJson);
			var jsonResult:Object = JSON.parse(modelInfoJson);
			var mi:ModelInfo = new ModelInfo();
			mi.initJSON( $vmd.guid, jsonResult );

			var oxelBA:ByteArray = new ByteArray();
			oxelBA.writeBytes( $ba, $ba.position, $ba.bytesAvailable );
			
			vm.loadOxelFromByteArray( $ba );
		
			vm.complete = true;
			return vm;
		}
	*/
}	
}