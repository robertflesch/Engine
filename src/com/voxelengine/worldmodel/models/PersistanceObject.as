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
	private var 	_guid:String;
	private var 	_table:String;
	private var 	_changed:Boolean;
	private var 	_dbo:DatabaseObject;
	private var 	_info:Object;
	
	
	public function PersistanceObject( $guid:String, $table:String ) {
		if ( null == $guid || "" == $guid )
			throw new Error( "PersistanceObject - Missing guid in constructor" );
		_guid = $guid;
		_table = $table;
	}

	public function release():void {
		_guid = null;
		_table = null;
		_dbo = null;
	}
	
	public function get info():Object { return _info; }
	public function set info(val:Object):void { _info = val; }
	public function get guid():String  { return _guid; }
	public function set guid(value:String):void { _guid = value; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo(val:DatabaseObject ):void { _dbo = val; }
	public function get table():String { return _table; }
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void { _changed = value; }
	
	public function clone( $guid:String ):* {
		throw new Error( "PersistanceObject.clone - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}
	
	protected function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
	}
	
	protected function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
	}
	
	protected function toObject():void { }
	
	public function save():void {
		if ( Globals.online && changed ) {
			//Log.out( "PersistanceObject.save - Saving to guid: " + guid  + " in table: " + table, Log.WARN );
			addSaveEvents();
			toObject();
			changed = false;
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, dbo, null ) );
		}
		else {
			if ( Globals.online && !changed )
				Log.out( "PersistanceObject.save - Not saving data - guid: " + guid + " NOT changed" );
			//else if ( !Globals.online && changed )
			//	Log.out( "PersistanceObject.save - Not saving data - guid: " + guid + " NOT online" );
			//else	
			//	Log.out( "PersistanceObject.save - Not saving data - Offline and not changed" );
		}
				
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "PersistanceObject.saveSucceed - save: " + guid + " in table: " + $pe.table ); 
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

	protected function addLoadEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSuccess );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, notFound );
	}
	
	protected function removeLoadEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, loadSuccess );
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_NOT_FOUND, notFound );
	}

	protected function notFound($pe:PersistanceEvent):void {
		throw new Error( "PersistanceObject.notFound - Must be overridden" );
	}
	
	protected function loadSuccess( $pe:PersistanceEvent ):void {
		throw new Error( "PersistanceObject.loadSuccess - Must be overridden" );
	}
	
	protected function loadFailed( $pe:PersistanceEvent ):void  {
		throw new Error( "PersistanceObject.loadFailed - Must be overridden" );
	}
}
}

