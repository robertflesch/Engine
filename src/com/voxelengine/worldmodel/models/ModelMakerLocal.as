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
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.MetadataManager;
import com.voxelengine.worldmodel.models.ModelData;
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
	private var _vmd:ModelData;
	private var _vmi:ModelInfo;
	
	public function ModelMakerLocal( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMakerLocal - ii: " + _ii.toString() );
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, _ii.guid, null ) );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.REQUEST, _ii.guid, null ) );		

		_makerCount++;
	}
	
	private function failedInfo( $mie:ModelInfoEvent):void {
		Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelInfoEvent: " + $mie.toString(), Log.WARN );
		markComplete();
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		Log.out( "ModelMaker.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
		markComplete()
	}
	
	
	private function retriveInfo(e:ModelInfoEvent):void {
		if ( _ii.guid == e.guid ) {
			ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );
			_vmi = e.vmi;
			attemptMake();
		}
	}
	
	private function retriveData(e:ModelDataEvent):void  {
		if ( _ii.guid == e.guid ) {
			ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
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
			markComplete();
		}
	}
	//////////////////////////////////////
	
	private function markComplete():void {
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		
		_makerCount--;
		if ( 0 == _makerCount )
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
		Log.out( "ModelMakerLocal.markComplete - makerCount: " + _makerCount );
	}
	
	
}	
}