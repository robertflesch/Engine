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
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;
//import org.flashapi.swing.Alert;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a models data, it is used by all of the current Makers
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes. 
	 * Not sure what a failure case for a timeout would be would be
	 */
public class ModelMakerBase {
	
	protected var _ii:InstanceInfo;
	protected var _vmd:ModelData;
	protected var _vmdFailed:Boolean;
	static private var _makerCount:int;
	private var   _parentModelGuid:String;
	
	static private var _s_parentChildCount:Array = new Array();

	
	public function ModelMakerBase( $ii:InstanceInfo, $fromTables:Boolean = true ) {
		_ii = $ii;
		if ( $ii.controllingModel ) {
			_parentModelGuid = $ii.controllingModel.instanceInfo.instanceGuid;
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = ++count;
		}
		//Log.out( "ModelMakerBase - ii: " + _ii.toString(), Log.DEBUG );
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.RESULT, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null, $fromTables ) );		
	}
	
	private function retriveData($mde:ModelDataEvent):void  {
		if ( _ii.modelGuid == $mde.modelGuid ) {
			//Log.out( "ModelMakerBase.retriveData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
			_vmd = $mde.vmd;
			if ( true ==  _vmdFailed ) {
				Log.out( "ModelMakerBase.retriveData - RESETTING VMDFAILED", Log.WARN );
				_vmdFailed = false;
			}
			attemptMake();
		}
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		if ( _ii.modelGuid == $mde.modelGuid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
			_vmdFailed = true;
//			markComplete( false );
		}
	}
	
	// once they both have been retrived, we can make the object
	protected function attemptMake():void { }
	protected function markComplete( $success:Boolean = true ):void {
		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.RESULT, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		if ( $success )
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _ii.modelGuid ) );
		else	
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_FAILURE, _ii.modelGuid ) );
		
		//Log.out( "ModelMakerBase.markComplete - " + ($success ? "SUCCESS" : "FAILURE" ) + "  ii: " + _ii + "  success: " + $success, Log.DEBUG );
		
		if ( _parentModelGuid ) {
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = --count;
			// This tells the PARENT that it is ready to move forward (save in particular)
			if ( 0 == count )
				ModelLoadingEvent.dispatch( new ModelLoadingEvent( ModelLoadingEvent.CHILD_LOADING_COMPLETE, _parentModelGuid ) );
		}

	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Make sense, called from for Makers
	static protected function modelMetaInfoRead( $ba:ByteArray ):Object {
		$ba.position = 0;
		// Read off first 3 bytes, the data format
		var format:String = readFormat($ba);
		if ("ivm" != format)
			throw new Error("ModelMakerBase.modelMetaInfoRead - Exception - unsupported format: " + format );
		
		var metaInfo:Object = new Object();
		// Read off next 3 bytes, the data version
		metaInfo.version = readVersion($ba);

		// Read off next byte, the manifest version
		metaInfo.manifestVersion = $ba.readByte();
		//Log.out("VoxelModel.readMetaInfo - version: " + metaInfo.version + "  manifestVersion: " + metaInfo.manifestVersion );
		return metaInfo;

		// This reads the format info and advances position on byteArray
		function readFormat($ba:ByteArray):String
		{
			var format:String;
			var byteRead:int = 0;
			byteRead = $ba.readByte();
			format = String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			format += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			format += String.fromCharCode(byteRead);
			
			return format;
		}
		
		// This reads the version info and advances position on byteArray
		function readVersion($ba:ByteArray):int
		{
			var version:String;
			var byteRead:int = 0;
			byteRead = $ba.readByte();
			version = String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			version += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			version += String.fromCharCode(byteRead);
			
			return int(version);
		}
	}
	
	// Makes sense
	static protected function instantiate( $ii:InstanceInfo, $modelInfo:ModelInfo, $vmm:ModelMetadata ):* {
		var modelAsset:String = $modelInfo.modelClass;
		var modelClass:Class = ModelLibrary.getAsset( modelAsset )
		var vm:VoxelModel = new modelClass( $ii );
		if ( null == vm )
			throw new Error( "ModelMakerBase.instantiate - Model failed in creation - modelClass: " + modelClass );
			
		vm.init( $modelInfo, $vmm );

		//Log.out( "ModelMakerBase.instantiate - modelClass: " + modelClass + "  instanceInfo: " + $ii.toString() );
		return vm;
	}
	
	static public function load( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean = true, $prompt:Boolean = true ):void {
		//Log.out( "ModelMakerBase.load ii: " + $ii.toString() );
		if ( !Globals.isGuid( $ii.modelGuid ) && $ii.modelGuid != "LoadModelFromBigDB" )
			if ( Globals.online )
				new ModelMakerImport( $ii, $prompt );
			else
				new ModelMakerLocal( $ii );
		else
			new ModelMaker( $ii, $addToRegionWhenComplete );
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MAY BE NEEDED
	static public function modelInfoPreload( $fileName:String ):void {
		throw new Error( "This is not needed online" );
		modelInfoFindOrCreate( $fileName, "", false );
	}
	
	
	static public function makerCountGet():int 
	{
		return _makerCount;
	}
	static public function makerCountIncrement():void 
	{
		_makerCount++;
		//Log.out( "ModelMakerBase.makerCountIncrement - makerCount: " + _makerCount, Log.ERROR );
	}
	
	static public function makerCountDecrement():void 
	{
		_makerCount--;
		//Log.out( "ModelMakerBase.makerCountDecrement - makerCount: " + _makerCount, Log.ERROR );
	}
}	
}