/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{

import com.voxelengine.worldmodel.models.makers.ModelMakerBase;

import flash.utils.Dictionary;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

public class AmmoCache {
	// this acts as a holding spot for all model objects loaded from persistence
	// don't use weak keys since this is THE spot that holds things.
	static private var _ammoData:Dictionary = new Dictionary(false);
	
	public function AmmoCache() {}
	
	static public function init():void {
		AmmoEvent.addListener( ModelBaseEvent.REQUEST, request );
		AmmoEvent.addListener( ModelBaseEvent.REQUEST_TYPE, requestType );

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	static private function requestType( $ae:AmmoEvent ):void {
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, $ae.series, Globals.BIGDB_TABLE_AMMO, $ae.guid, null, Globals.BIGDB_TABLE_AMMO_INDEX_WEAPON_TYPE ) );
		for each ( var ammo:Ammo in _ammoData ) {
			if ( ammo.weaponType == $ae.guid )
				AmmoEvent.dispatch(new AmmoEvent(ModelBaseEvent.RESULT, 0, ammo.guid, ammo));
		}
	}

	static private function request( $ae:AmmoEvent ):void {
		if ( null == $ae.guid ) {
			Log.out( "AmmoCache.request guid requested is NULL", Log.WARN );
			return;
		}
		//Log.out( "AmmoCache.request guid: " + $ae.guid, Log.INFO );
		var ammo:Ammo = _ammoData[$ae.guid]; 
		if ( null == ammo ) {
			if ( true == Globals.online && $ae.fromTable )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ae.series, Globals.BIGDB_TABLE_AMMO, $ae.guid ) );
			else	
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ae.series, Globals.AMMO_EXT, $ae.guid ) );
		}
		else
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.RESULT, $ae.series, $ae.guid, ammo ) );
	}
	
	static private function add($pe:PersistenceEvent, $ammo:Ammo ):void {
		if ( null == $ammo || null == $pe.guid ) {
			Log.out( "AmmoCache.add trying to add NULL ammo or guid", Log.WARN );
			return;
		}
		var ammo:Ammo = _ammoData[$pe.guid];
		// check to make sure this is new data
		if ( null == ammo ) {
			ammo = $ammo;
			_ammoData[$pe.guid] = $ammo; 
		}
		else {
			Log.out( "AmmoCache.add Trying to add the same ammo twice " + $pe.toString(), Log.WARN );
		}
		AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.RESULT, $pe.series, $pe.guid, $ammo ) );
	}
	
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			//Log.out( "AmmoCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var ammo:Ammo;
			if ( $pe.dbo ) {
				ammo = new Ammo( $pe.guid, $pe.dbo, null );
			}
			else {
				var fileData:String = String( $pe.data );
				fileData = StringUtils.trim(fileData);
				var newObjData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "ModelInfoCache.loadSucceed" );
				if ( null == newObjData ) {
					Log.out( "AmmoCache.loadSucceed - error parsing ammoInfo on import. guid: " + $pe.guid, Log.ERROR );
					AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
					return;
				}
				ammo = new Ammo( $pe.guid, null, newObjData );
				if ( ammo.impactSound == "" && ammo.launchSound == "" )
					ammo.save( true );
			}
			add( $pe, ammo );
		}
		else {
			Log.out( "AmmoCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		Log.out( "AmmoCache.loadFailed this means the table is missing!" + $pe.toString(), Log.ERROR );
		AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( Globals.AMMO_EXT != $pe.table && Globals.BIGDB_TABLE_AMMO != $pe.table )
			return;
		// maybe this ammo has not been loaded into the table yet, try loading it from json file
		if ( Globals.BIGDB_TABLE_AMMO == $pe.table ) {
            if ( ModelMakerBase.isImporting )
                Log.out( "AmmoCache.loadNotFound - retrying from local object " + $pe.toString(), Log.WARN );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST, $pe.series, $pe.guid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );
		}
		else {	
			Log.out( "AmmoCache.loadNotFound guid: " + $pe.toString(), Log.ERROR );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
}
}