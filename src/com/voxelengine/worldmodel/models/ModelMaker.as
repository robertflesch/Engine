/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.Region;
import flash.utils.getTimer;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMaker extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	static public var _makerCount:int;
	
	private var _vmm:ModelMetadata;
	private var _addToRegionWhenComplete:Boolean;
	private var _time:int;
	
	public function ModelMaker( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean ) {
		_addToRegionWhenComplete = $addToRegionWhenComplete;
		_time = getTimer();
		super( $ii );
		if ( 0 == _makerCount )
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		_makerCount++;
		Log.out( "ModelMaker - makerCount: " + _makerCount );
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		

		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		Log.out( "ModelMaker.failedMetadata - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
		markComplete(false);
	}
	
	private function retriveMetadata(e:ModelMetadataEvent):void {
		if ( _ii.modelGuid == e.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );
			_vmm = e.vmm;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmm && null != _vmd ) {
			Log.out( "ModelMaker.attemptMake - ii: " + _ii.toString() );
			var vm:VoxelModel = createFromMakerInfo();
			if ( vm )
				Region.currentRegion.modelCache.add( vm );
				
			markComplete();
		}
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete();
		
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
		_makerCount--;
		if ( 0 == _makerCount ) {
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
		Log.out( "ModelMaker.markComplete - makerCount: " + _makerCount + " time: " + (getTimer()-_time) );
	}
	
	private function createFromMakerInfo():VoxelModel {
		var $ba:ByteArray = _vmd.ba;
		if ( null == $ba )
		{
			Log.out( "ModelMaker.createFromMakerInfo - Exception - bad data in VoxelModelMetadata: " + _vmd.guid, Log.ERROR );
			return null;
		}
		$ba.position = 0;
		
		var versionInfo:Object = ModelLoader.modelMetaInfoRead( $ba );
		if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
		{
			Log.out( "ModelMaker.createFromMakerInfo - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
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
		mi.initJSON( _vmd.guid, jsonResult );
		
		// add the modelInfo to the repo
		// is the still needed TODO - RSF 9.23.14
//			Globals.modelInfoAdd( mi );
		// needs to be name + guid??
		
		//var vm:* = instantiate( $ii, mi, $vmm );
		var vm:* = ModelLoader.instantiate( _ii, mi, _vmm );
		if ( vm ) {
			vm.version = versionInfo.version;
			vm.fromByteArray( $ba );
			vm.complete = true;
		}

		vm.data = _vmd;
		return vm;
	}
}	
}