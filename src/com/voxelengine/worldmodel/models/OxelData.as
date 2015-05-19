/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
/**
 * ...
 * @author Robert Flesch - RSF
 * OxelData is the byte level representation of the oxel
 */
public class OxelData
{
	private var _modelGuid:String;
	private var _dbo:DatabaseObject;
	private var _compressedBA:ByteArray;
	
	public function OxelData( $guid:String ) {
		_modelGuid = $guid;
//		if ( "EditCursor" != $guid )
//			OxelData.addListener( ModelBaseEvent.SAVE, saveEvent );
	}

	public function release():void {
//		OxelData.removeListener( ModelBaseEvent.SAVE, saveEvent );
	}
	
	public function get modelGuid():String  { return _modelGuid; }
	public function set modelGuid(value:String):void { _modelGuid = value; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function get compressedBA():ByteArray  { return _compressedBA;  }
	public function set compressedBA( $ba:ByteArray ):void  { _compressedBA = $ba; }
	
	public function clone():OxelData {
		var vmd:OxelData = new OxelData( _modelGuid );
		vmd._dbo = dbo; // Can I just reference this? They are pointing to same object
		var ba:ByteArray = new ByteArray();
		ba.writeBytes( _compressedBA, 0, _compressedBA.length );
		vmd._compressedBA = ba;
		return vmd;
	}
	
	public function save( ba:ByteArray ):void {
		if ( Globals.online ) {
			Log.out( "OxelData.save - Saving OxelData: " + modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			_compressedBA = ba;
			_compressedBA.compress();
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else
				var obj:Object = toObject();
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA, modelGuid, _dbo, obj ) );
		}
		else
			Log.out( "OxelData.save - Not saving data, either offline or NOT changed or locked - guid: " + modelGuid, Log.WARN );
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA != $pe.table )
			return;
		removeSaveEvents();
		//Log.out( "OxelData.saveSucceed - save: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "OxelData.createSuccess - created: " + modelGuid + "  DBO FOUND", Log.DEBUG ); 
	}	
	
	private function createFailed( $pe:PersistanceEvent ):void  {
		if ( Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA != $pe.table )
			return;
		removeSaveEvents();
		// TODO How do I handle the metadata for failed object?
		Log.out( "OxelData.createFailed - created: " + modelGuid, Log.ERROR ); 
		
	}
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "OxelData.saveFail - ", Log.ERROR ); 
	}	
	
	public function toPersistance():void {
		_dbo.ba			= _compressedBA;
	}
	
	private function toObject():Object {
		return { ba: _compressedBA }
	}

	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo			= $dbo;
		_compressedBA = $dbo.ba;
	}
	
}
}

