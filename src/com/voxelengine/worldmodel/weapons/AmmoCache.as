/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.net.URLLoaderDataFormat;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ModelBaseEvent;

/**
 * ...
 * @author Bob
 */
public class AmmoCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _ammoData:Dictionary = new Dictionary(false);
	
	public function AmmoCache() {}
	
	static public function init():void {
		AmmoEvent.addListener( ModelBaseEvent.REQUEST, request );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  modelData
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $ae:AmmoEvent ):void 
	{   
		if ( null == $ae.name ) {
			Log.out( "AmmoCache.request name requested is NULL", Log.WARN );
			return;
		}
		Log.out( "AmmoCache.request name: " + $ae.name, Log.INFO );
		var ammo:Ammo = _ammoData[$ae.name]; 
		if ( null == ammo ) {
			if ( true == Globals.online && $ae.fromTable )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.BIGDB_TABLE_AMMO, $ae.name ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.AMMO_EXT, $ae.name ) );
		}
		else
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.RESULT, $ae.series, $ae.name, ammo ) );
	}
	
	static private function add( $pe:PersistanceEvent, $ammo:Ammo ):void 
	{ 
		if ( null == $ammo || null == $pe.guid ) {
			Log.out( "AmmoCache.add trying to add NULL ammo or name", Log.WARN );
			return;
		}
		// check to make sure this is new data
		if ( null ==  _ammoData[$pe.guid] ) {
			_ammoData[$pe.guid] = $ammo; 
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, $ammo ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		var imported:Boolean;	
		if ( $pe.dbo || $pe.data ) {
			//Log.out( "AmmoCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var ammo:Ammo = new Ammo( $pe.guid );
			if ( !$pe.dbo ) {
				imported = true;
				ammo.dbo = new DatabaseObject( Globals.BIGDB_TABLE_AMMO, $pe.guid, "0", 0, true, null );
				ammo.dbo.ammo = JSONUtil.parse( $pe.data, $pe.guid + $pe.table, "AnimationCache.loadSucceed" );
				if ( null == ammo.dbo.ammo ) {
					Log.out( "AmmoCache.loadSucceed - error parsing ammo data on import. guid: " + $pe.guid, Log.ERROR );
					AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
					return;
				}
				ammo.guid = $pe.guid;
			}
			else
				ammo.dbo = $pe.dbo;
				
			ammo.fromPersistance( ammo.dbo );
			add( $pe, ammo );
			if ( imported )
				ammo.save();
		}
		else {
			Log.out( "AmmoCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		Log.out( "AmmoCache.loadFailed this means the table is missing!" + $pe.toString(), Log.ERROR );
		AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		// maybe this ammo has not been loaded into the table yet, try loading it from json file
		if ( Globals.BIGDB_TABLE_AMMO == $pe.table ) {
			Log.out( "AmmoCache.loadNotFound - retrying from json " + $pe.toString(), Log.WARN );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST, $pe.series, $pe.guid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );
		}
		else {	
			Log.out( "AmmoCache.loadNotFound guid: " + $pe.toString(), Log.ERROR );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
}
}