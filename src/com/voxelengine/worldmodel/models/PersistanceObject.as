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
 * PersistanceObject is the byte level representation of the oxel
 */
public class PersistanceObject
{
	protected var _dbo:DatabaseObject;
	private var _guid:String;
	protected var _obj:Object;
	private var _table:String;
	
	public function PersistanceObject( $guid:String, $table:String ) {
		if ( null == $guid || "" == $guid )
			throw new Error( "PersistanceObject - Missing guid in constructor" );
		_guid = $guid;
		_table = $table;
	}

	public function release():void {
	}
	
	public function get guid():String  { return _guid; }
	public function set guid(value:String):void { _guid = value; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo(val:DatabaseObject ):void { _dbo = val; }
	
	public function clone():* {
		throw new Error( "PersistanceObject.clone - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}
	
	public function save():void {
		if ( Globals.online ) {
			Log.out( "PersistanceObject.save - Saving PersistanceObject: " + guid  + " in table: " + _table );
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else
				_obj = toObject();
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, _table, _guid, _dbo, _obj ) );
		}
		else
			Log.out( "PersistanceObject.save - Not saving data, either offline or NOT changed or locked - guid: " + _guid, Log.WARN );
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
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "PersistanceObject.saveSucceed - save: " + guid + " in table: " + $pe.table, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "PersistanceObject.createSuccess - created: " + guid + " in table: " + $pe.table, Log.DEBUG ); 
	}	
	
	private function createFailed( $pe:PersistanceEvent ):void  {
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		// TODO How do I handle the metadata for failed object?
		Log.out( "PersistanceObject.createFailed - created: " + guid + " in table: " + $pe.table, Log.ERROR ); 
		
	}
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "PersistanceObject.saveFail - guid: " + guid + " in table: " + $pe.table, Log.ERROR ); 
	}	
	
	protected function toPersistance():void {
		throw new Error( "PersistanceObject.toPersistance - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}
	
	protected function toObject():Object {
		throw new Error( "PersistanceObject.toObject - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}

	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		throw new Error( "PersistanceObject.fromPersistance - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}
	
}
}

