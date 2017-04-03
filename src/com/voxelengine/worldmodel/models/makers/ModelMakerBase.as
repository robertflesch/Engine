/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent
import com.voxelengine.events.LoadingEvent
import com.voxelengine.events.LoadingImageEvent
import com.voxelengine.events.ModelLoadingEvent
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.*
import com.voxelengine.worldmodel.models.types.VoxelModel

import flash.geom.Vector3D;

import org.flashapi.swing.Alert;

/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a models data, it is used by all of the current Makers
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes. 
	 * Not sure what a failure case for a timeout would be would be
	 */
public class ModelMakerBase {
	
	static private var _makerCount:int;
	
	protected   	var _modelMetadata:ModelMetadata;
	
	protected 	       var _modelInfo:ModelInfo;
	protected function get modelInfo():ModelInfo { return _modelInfo }
	
	private   		   var _ii:InstanceInfo;
	protected function get ii():InstanceInfo { return _ii }
	
	private   		   var _parentModelGuid:String;
	protected function get parentModelGuid():String { return _parentModelGuid }
	
	static private var _s_parentChildCount:Array = [];
	protected  			var _vm:VoxelModel;
	protected 			var _addToRegionWhenComplete:Boolean = true;


	/*
	//   This generates either a
	//	 ModelLoadingEvent.MODEL_LOAD_COMPLETE
	//	 ModelLoadingEvent.MODEL_LOAD_FAILURE
	//   event
	*/

	public function ModelMakerBase( $ii:InstanceInfo, $fromTables:Boolean = true ) {
		if ( null == $ii )
			throw new Error( "ModelMakerBase - NO instanceInfo recieve in constructor" );
		//Log.out( "ModelMakerBase - ii: " + $ii.toString(), Log.DEBUG )
		_ii = $ii;
		//Log.out( "ModelMakerBase - _ii.modelGuid: " + _ii.modelGuid );

		if ( $ii.controllingModel ) {
			//Log.out( "ModelMakerBase - _ii.modelGuid: " + _ii.modelGuid + "  $ii.controllingModel: " + $ii.controllingModel);
			// Using modelGuid rather then instanceGuid since imported models have no instanceGuid at this point.
			// No sure if using model guid has a down side or not.
			//Log.out( "ModelMakerBase has controlling model - modelGuid of parent: " + $ii.controllingModel.instanceInfo.modelGuid, Log.WARN )
			_parentModelGuid = $ii.controllingModel.instanceInfo.modelGuid;
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = ++count
		}
	}
	
	protected function retrieveBaseInfo():void {
		//Log.out( "ModelMakerBase.retrieveBaseInfo - _ii.modelGuid: " + _ii.modelGuid );
		addListeners();
		ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null );
	}
	
	protected function addListeners():void {
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retrievedModelInfo );
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retrievedModelInfo );
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
	}
	
	
	protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
		if (_ii &&  _ii.modelGuid == $mie.modelGuid ) {
			//Log.out( "ModelMakerBase.retrievedModelInfo - ii: " + _ii.toString(), Log.DEBUG )
			removeListeners();
			_modelInfo = $mie.vmi;
			attemptMake();
		}
	}
		
	protected function failedModelInfo( $mie:ModelInfoEvent):void  {
		if ( _ii && _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + _ii.toString(), Log.WARN );
			removeListeners();
			markComplete( false );
		}
	}
	
	// check to make sure all of info required is here
	protected function attemptMake():void { throw new Error( "ModelMakerBase.attemptMake is an abstract method" ) }
	
	// once they both have been retrieved, we can make the object
	protected function make():VoxelModel {
		var modelAsset:String = _modelInfo.modelClass;
		var modelClass:Class = ModelLibrary.getAsset( modelAsset );
		if ( null == _ii.instanceGuid )
			 _ii.instanceGuid = Globals.getUID();
		
		var vm:VoxelModel = new modelClass( _ii );
		if ( null == vm ) {
			Log.out( "ModelMakerBase.make - Model failed in creation - modelAsset: " + modelAsset + "  modelClass: " + modelClass, Log.ERROR );
			return null
		}
		vm.init( _modelInfo, _modelMetadata );
		return vm;

	}

	private function removeListeners():void {
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retrievedModelInfo );
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrievedModelInfo );
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
	}

	protected function markComplete( $success:Boolean ):void {
		if ( $success ) {
			_vm.complete = true;

			if ( _vm && _addToRegionWhenComplete )
				RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, _vm );
			RegionEvent.create(ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null);
			ModelLoadingEvent.dispatch(new ModelLoadingEvent(ModelLoadingEvent.MODEL_LOAD_COMPLETE, _ii.modelGuid, _parentModelGuid, _vm ));
		}
		else
			ModelLoadingEvent.dispatch(new ModelLoadingEvent(ModelLoadingEvent.MODEL_LOAD_FAILURE, _ii.modelGuid, _parentModelGuid));

		_modelMetadata = null;
		_modelInfo = null;
		_ii = null;
		_vm = null;
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// A factory method to build the correct object
	static public function load( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean = true, $addToCountORPrompt:Boolean = true ):void {
		//Log.out( "ModelMakerBase.load - choose maker ii: " + $ii.toString() )
		if ( !Globals.isGuid( $ii.modelGuid ) )
			if ( Globals.online )
				new ModelMakerImport( $ii, $addToCountORPrompt );
			else
				new ModelMakerLocal( $ii );
		else
			new ModelMaker( $ii, $addToRegionWhenComplete, $addToCountORPrompt );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	static public function makerCountGet():int { return _makerCount }
	static public function makerCountIncrement():void { 
		if ( 0 == makerCountGet() )
			LoadingImageEvent.create( LoadingImageEvent.CREATE );
		_makerCount++;
	}
	static public function makerCountDecrement():void { 
		_makerCount-- ;
		if ( 0 == makerCountGet() ) {
			LoadingImageEvent.create( LoadingImageEvent.DESTROY );
			RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
		}
	}
	
}	
}