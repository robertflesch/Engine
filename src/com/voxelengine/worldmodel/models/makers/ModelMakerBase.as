/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;

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
	
	protected var _vmm:ModelMetadata;
	protected var _vmi:ModelInfo;
	protected var _ii:InstanceInfo;
	protected var _parentModelGuid:String;
	
	static private var _s_parentChildCount:Array = new Array();
	
	public function ModelMakerBase( $ii:InstanceInfo, $fromTables:Boolean = true ) {
		Log.out( "ModelMakerBase - ii: " + $ii.toString(), Log.DEBUG );
		_ii = $ii;
		if ( $ii.controllingModel ) {
			// Using modelGuid rather then instanceGuid since imported models have no instanceGuid at this point.
			// No sure if using model guid has a down side or not.
			//Log.out( "ModelMakerBase has controlling model - modelGuid of parent: " + $ii.controllingModel.instanceInfo.modelGuid, Log.WARN );
			_parentModelGuid = $ii.controllingModel.instanceInfo.modelGuid;
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = ++count;
		}
	}
	
	protected function retrieveBaseInfo():void {
		addListeners();	
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );	
	}
	
	protected function addListeners():void {
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retrivedModelInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retrivedModelInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );		
	}
	
	
	protected function retrivedModelInfo($mie:ModelInfoEvent):void  {
		if ( _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerBase.retrivedModelInfo - ii: " + _ii.toString(), Log.DEBUG );
			_vmi = $mie.vmi;
			attemptMake();
		}
	}
		
	protected function failedModelInfo( $mie:ModelInfoEvent):void  {
		if ( _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + _ii.toString(), Log.WARN );
			markComplete( false );
		}
	}
	
	// check to make sure all of info required is here
	protected function attemptMake():void { throw new Error( "ModelMakerBase.attemptMake is an abstract method" ); }
	
	// once they both have been retrived, we can make the object
	protected function make():VoxelModel {
		var modelAsset:String = _vmi.modelClass;
		var modelClass:Class = ModelLibrary.getAsset( modelAsset )
		var vm:VoxelModel = new modelClass( _ii );
		if ( null == vm ) {
			Log.out( "ModelMakerBase.make - Model failed in creation - modelAsset: " + modelAsset + "  modelClass: " + modelClass, Log.ERROR );
			return null;
		}
		vm.init( _vmi, _vmm );
		return vm;
	}

	protected function markComplete( $success:Boolean = true ):void {
		removeListeners();
		if ( $success )
			ModelLoadingEvent.dispatch( new ModelLoadingEvent( ModelLoadingEvent.MODEL_LOAD_COMPLETE, _ii.modelGuid ) );
		else	
			ModelLoadingEvent.dispatch( new ModelLoadingEvent( ModelLoadingEvent.MODEL_LOAD_FAILURE, _ii.modelGuid ) );
		
		//Log.out( "ModelMakerBase.markComplete - " + ($success ? "SUCCESS" : "FAILURE" ) + "  ii: " + _ii + "  success: " + $success, Log.DEBUG );
		if ( _parentModelGuid ) {
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = --count;
			if ( 0 == count )
				ModelLoadingEvent.dispatch( new ModelLoadingEvent( ModelLoadingEvent.CHILD_LOADING_COMPLETE, _ii.modelGuid, _parentModelGuid ) );
		}
		_vmm = null;
		_vmi = null;
		_ii = null;
		
		function removeListeners():void {
			ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retrivedModelInfo );		
			ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrivedModelInfo );		
			ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );	
		}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// A factory method to build the correct object
	static public function load( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean = true, $prompt:Boolean = true ):void {
		//Log.out( "ModelMakerBase.load - choose maker ii: " + $ii.toString() );
		if ( !Globals.isGuid( $ii.modelGuid ) )
			if ( Globals.online )
				new ModelMakerImport( $ii, $prompt );
			else
				new ModelMakerLocal( $ii );
		else
			new ModelMaker( $ii, $addToRegionWhenComplete );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	static public function makerCountGet():int { return _makerCount; }
	static public function makerCountIncrement():void { _makerCount++; }
	static public function makerCountDecrement():void { _makerCount--; }
}	
}