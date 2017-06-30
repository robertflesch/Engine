/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.Player;

import flash.utils.getQualifiedClassName;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistenceEvent;
/**
 * ...
 * @author Robert Flesch - RSF
 * PersistenceObject is the byte level representation of the oxel
 */
public class PersistenceObject
{

	// BigDB doesn't like another save call in the middle of an existing one.
	// So if we are in the "SAVING state, leave object "changed" and return.
	protected var 	_saving:Boolean;

	private var 	_doNotPersist:Boolean;
	public function get doNotPersist():Boolean { return _doNotPersist; }
	public function set doNotPersist(value:Boolean):void { _doNotPersist = value; }

	public function get createdDate():String { return dbo.createdDate; }
	public function get creator():String { return dbo.creator; }


	private var 	_guid:String;
	public function get guid():String  { return _guid; }
	public function set guid(value:String):void	{
//		if ( _guid != value && Globals.isGuid( _guid ) && Globals.isGuid( value ) )
//				Log.out( "PersistenceObject - WHY AM I CHANGING A VALID GUID  _guid: " + _guid + "  newGuid: " + value );
		_guid = value;
		changed = true;
	}

	private var 	_dbo:DatabaseObject;
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo(val:DatabaseObject ):void { _dbo = val; }
	private var 	_table:String;
	public function get table():String { return _table; }

	private var 	_changed:Boolean  = false;
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void {
//		if ( value )
//			Log.out( "PersistenceObject.Changed value: " + value + "  guid: " + _guid, Log.WARN);
		_changed = value; }

	public function PersistenceObject($guid:String, $table:String ) {
		if ( null == $guid || "" == $guid )
			throw new Error( "PersistenceObject - Missing guid in constructor" );
		_guid = $guid;
		_table = $table;
		_saving = false;
	}

	protected function assignNewDatabaseObject():void {
		dbo = new DatabaseObject( table, "0", "0", 0, true, null);
		dbo.createdDate	= new Date().toUTCString();
		dbo.creator	= Network.userId;
	}

	public function clone( $guid:String ):* {
		throw new Error( "PersistenceObject.clone - THIS METHOD NEEDS TO BE OVERRIDDEN", Log.ERROR );
	}

	public function release():void {
		_guid = null;
		_table = null;
		_dbo = null;
	}

	protected function addSaveEvents():void {
		//Log.out( getQualifiedClassName( this ) + ".addSaveEvents - guid: " + guid, Log.DEBUG );
		PersistenceEvent.addListener( PersistenceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistenceEvent.addListener( PersistenceEvent.CREATE_FAILED, 	createFailed );
		PersistenceEvent.addListener( PersistenceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistenceEvent.addListener( PersistenceEvent.SAVE_FAILED, 	saveFail );
		_saving = true;
	}
	
	protected function removeSaveEvents():void {
		//Log.out( getQualifiedClassName( this ) + ".removeSaveEvents - guid: " + guid, Log.DEBUG );
		PersistenceEvent.removeListener( PersistenceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistenceEvent.removeListener( PersistenceEvent.CREATE_FAILED, 	createFailed );
		PersistenceEvent.removeListener( PersistenceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistenceEvent.removeListener( PersistenceEvent.SAVE_FAILED, 		saveFail );
		_saving = false;
		// if I changed came in while I was saving, the object will still be dirty.
		// So go head and save it again.
		if ( changed )
			save();
	}
	
	protected function toObject():void { }
	
	public function save():Boolean {
		if ( !changed || !Globals.online || doNotPersist ) {
//			if ( Globals.online && !changed )
//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT changed" );
//			else if ( !Globals.online && changed )
//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT online" );
//			else
//				Log.out( name + " save - Not saving data - Offline and not changed" );
			return false;
		}

		if ( !Globals.isGuid(guid)) {
			changed = false;
			return false;
		}
		validatedSave();
		return true;
	}

	protected function validatedSave():void {
		//var name:String = getQualifiedClassName(this);
		if ( _saving ) {
			//Log.out("PersistenceObject.save - IN MIDDLE OF SAVE: " + name, Log.WARN);
			return;
		}

		changed = false;
		//Log.out(name + ".save - Saving to guid: " + guid + " in table: " + table, Log.DEBUG);
		addSaveEvents();
		toObject();
		if (dbo && dbo.changed)
			delete dbo.changed;

		PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.SAVE_REQUEST, 0, table, guid, dbo, null));
	}
	
	private function saveSucceed( $pe:PersistenceEvent ):void {
		if ( table != $pe.table )
			return;
		//Log.out(getQualifiedClassName(this) + ".saveSucceed. guid: " + guid + " in table: " + table, Log.DEBUG);
		if ( guid == $pe.guid ) {
			removeSaveEvents();
			//Log.out(getQualifiedClassName( this ) + ".PersistenceObject.saveSucceed - save: " + guid + " in table: " + $pe.table);
		}
	}	
	
	private function createSucceed( $pe:PersistenceEvent ):void {
		if ( table != $pe.table )
			return;
		//Log.out(getQualifiedClassName(this) + ".createSucceed. guid: " + guid + " in table: " + table, Log.DEBUG);
		if ( $pe.dbo && guid == $pe.guid ) {
			// the create result was coming back after some additional saves had been made
			// this was causing data to be lost!! So first save data, then copy over dbo, then restore data!
			_dbo = $pe.dbo;
			removeSaveEvents();
//			if ( dbo )
//				Log.out( getQualifiedClassName( this ) + ".PersistenceObject.createSuccess - created: " + guid + " in table: " + $pe.table, Log.DEBUG );
//			else
//				Log.out(getQualifiedClassName( this ) + ".PersistenceObject.createSuccess - ERROR: " + guid + " in table: " + $pe.table, Log.ERROR);
		}
		else {
			if ( !$pe.dbo )
				Log.out("PersistenceObject.createSucceed NO DBO Object this: " + this, Log.ERROR );
			//else
			//	Log.out( getQualifiedClassName( this ) + ".PersistenceObject.createSucceed ---- BUT guid: " + guid + " !=  $pe.dbo.guid: " + $pe.dbo.key, Log.DEBUG );
		}
	}
	
	private function createFailed( $pe:PersistenceEvent ):void  {
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		// TODO How do I handle the metadata for failed object?
		Log.out( getQualifiedClassName( this ) + ".createFailed - created: " + guid + " in table: " + $pe.table, Log.ERROR ); 
		
	}
	
	private function saveFail( $pe:PersistenceEvent ):void {
		if ( _table != $pe.table )
			return;
		removeSaveEvents();
		Log.out( getQualifiedClassName( this ) + ".saveFail - guid: " + guid + " in table: " + $pe.table, Log.ERROR ); 
	}	

	protected function addLoadEvents():void {
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, loadSuccess );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, notFound );
	}
	
	protected function removeLoadEvents():void {
		PersistenceEvent.removeListener( PersistenceEvent.LOAD_SUCCEED, loadSuccess );
		PersistenceEvent.removeListener( PersistenceEvent.LOAD_FAILED, loadFailed );
		PersistenceEvent.removeListener( PersistenceEvent.LOAD_NOT_FOUND, notFound );
	}

	protected function notFound($pe:PersistenceEvent):void {
		throw new Error( getQualifiedClassName( this ) + ".notFound - Must be overridden" );
	}
	
	protected function loadSuccess( $pe:PersistenceEvent ):void {
		throw new Error( getQualifiedClassName( this ) + ".loadSuccess - Must be overridden" );
	}
	
	protected function loadFailed( $pe:PersistenceEvent ):void  {
		throw new Error( getQualifiedClassName( this ) + ".loadFailed - Must be overridden" );
	}

	protected function mergeOverwrite( obj0:Object ):void {
		for( var p:String in obj0 ) {
			if ( null != obj0[ p ]) {
				dbo[p] = obj0[p];
				//trace("PersistenceObject.mergeOverwrite " + p, ' : obj0', obj0[p], 'dbo', dbo[p], '-> new value = ', dbo[p]);
			}
		}
	}

	protected function mergePreferExisting( obj0:Object ):void {
		for( var p:String in obj0 ) {
			dbo[ p ] = ( dbo[ p ] != null ) ? dbo[ p ] : obj0[ p ];
			trace( "PersistenceObject.merge " + p, ' : obj0', obj0[ p ], 'dbo', dbo[ p ], '-> new value = ', dbo[ p ] );
		}
	}

}
}

