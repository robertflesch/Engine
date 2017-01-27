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
import flash.utils.getQualifiedClassName;

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
	protected var 	_table:String;
	private var 	_guid:String;
	private var 	_changed:Boolean;
	private var 	_dynamicObj:Boolean;
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
	public function set info(val:Object):void {
		//Log.out( "PersistanceObject - info set to: " + JSON.stringify( val ) );
		_info = val; }
	public function get guid():String  { return _guid; }
	public function set guid(value:String):void	{
		if ( _guid != value && Globals.isGuid( _guid ) && Globals.isGuid( value ) )
				Log.out( "PersistanceObject - WHY AM I CHANGING A VALID GUID  _guid: " + _guid + "  newGuid: " + value );
		_guid = value;
	}
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo(val:DatabaseObject ):void { _dbo = val; }
	public function get table():String { return _table; }
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void {
		//Log.out( "PersistanceObject.Changed value: " + value + "  guid: " + _guid, Log.WARN);
		_changed = value; }
	
	public function get dynamicObj():Boolean { return _dynamicObj; }
	public function set dynamicObj(value:Boolean):void { _dynamicObj = value; }
	
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
		var name:String = getQualifiedClassName( this )
		if ( Globals.online && changed && !dynamicObj ) {
			changed = false;
//			Log.out( name + ".save - Saving to guid: " + guid  + " in table: " + table, Log.DEBUG );
			addSaveEvents();
			toObject();
			if ( info && info.changed )
				delete info.changed;
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, dbo, null ) );
		}
//		else {
//			if ( Globals.online && !changed )
//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT changed" );
//			else if ( !Globals.online && changed )
//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT online" );
//			else
//				Log.out( name + " save - Not saving data - Offline and not changed" );
//		}
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		//Log.out( getQualifiedClassName( this ) + ".saveSucceed - save: " + guid + " in table: " + $pe.table );
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		if ( $pe.dbo && guid == $pe.guid ) {
			// the create result was coming back after some additional saves had been made
			// this was causing data to be lost!! So first save data, then copy over dbo, then restore data!
			if ( dbo && dbo.data ) {
				Log.out( getQualifiedClassName( this ) + ".createSuccess - ALT PATH created: " + guid + " in table: " + $pe.table, Log.DEBUG );
				var dataBackup:Object = dbo.data;
				_dbo = $pe.dbo;
				for ( var key:String in dataBackup ) {
                    //Log.out( "PersistanceObject key: " + key );
					_dbo[key] = dataBackup[key];
				}
                if ( _dbo.data )
                        delete _dbo.data;
                changed = true;
                save();
			}
			else {
				Log.out(getQualifiedClassName(this) + ".createSuccess - created: " + guid + " in table: " + $pe.table, Log.DEBUG);
				_dbo = $pe.dbo;
			}
		}
		else {
			if ( !$pe.dbo ) {
				Log.out("PersistanceObject.createSucceed NO DBO Object this: " + this, Log.ERROR );
			} //else
				//Log.out( "PersistanceObject.createSucceed ---- BUT guid: " + guid + " !=  $pe.dbo.guid: " + $pe.dbo.key, Log.DEBUG )
		}
		removeSaveEvents();
	}
	
	private function createFailed( $pe:PersistanceEvent ):void  {
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		// TODO How do I handle the metadata for failed object?
		Log.out( getQualifiedClassName( this ) + ".createFailed - created: " + guid + " in table: " + $pe.table, Log.ERROR ); 
		
	}
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		Log.out( getQualifiedClassName( this ) + ".saveFail - guid: " + guid + " in table: " + $pe.table, Log.ERROR ); 
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
		throw new Error( getQualifiedClassName( this ) + ".notFound - Must be overridden" );
	}
	
	protected function loadSuccess( $pe:PersistanceEvent ):void {
		throw new Error( getQualifiedClassName( this ) + ".loadSuccess - Must be overridden" );
	}
	
	protected function loadFailed( $pe:PersistanceEvent ):void  {
		throw new Error( getQualifiedClassName( this ) + ".loadFailed - Must be overridden" );
	}
}
}

