/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.oxel.Lighting;

import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.net.URLLoaderDataFormat;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.PersistenceEvent;

/**
 * ...
 * @author Bob
 */
public class OxelPersistenceCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _loadingCount:int;
	static private var _oxelDataDic:Dictionary = new Dictionary(false);
	static private var _block:Block = new Block();
	
	public function OxelPersistenceCache() {}
	
	static public function init():void {
		// These are the events that this object listens for.
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST, 				request );
		OxelDataEvent.addListener( ModelBaseEvent.GENERATION, 			generated );
		OxelDataEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		OxelDataEvent.addListener( ModelBaseEvent.UPDATE_GUID, 			updateGuid );
		OxelDataEvent.addListener( ModelBaseEvent.SAVE, 				save );
		
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.GENERATE_SUCCEED,generateSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}

	static private function save(e:OxelDataEvent):void {
		for each ( var op:OxelPersistence in _oxelDataDic )
			if ( op )
				op.save();
	}

	static private function add( $series:int, $od:OxelPersistence ):void {
		if ( null == $od || null == $od.guid ) {
			Log.out( "OxelDataCache.Add trying to add NULL OxelData or guid", Log.WARN );
		} else if ( null == _oxelDataDic[$od.guid] ) { // check to make sure this is new data
			//Log.out( "OxelDataCache.add adding: " + $od.modelGuid, Log.INFO );
			_oxelDataDic[$od.guid] = $od; 
			if ( _block.has( $od.guid ) )
				_block.clear( $od.guid )
			_loadingCount--;
			OxelDataEvent.create( ModelBaseEvent.ADDED, $series, $od.guid, $od );
			if ( 0 == _loadingCount ) {
				//Log.out( "OxelPersistenceCache.add - done loading oxels: " + $od.guid, Log.WARN );
				// So does the loading of the VoxelModel or oxel complete region?
				//RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
			}
		} else
			Log.out( "OxelDataCache.Add trying to add duplicate OxelData", Log.WARN );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  OxelDataEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function updateGuid( $ode:OxelDataEvent ):void {
		var guidArray:Array = $ode.modelGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var oxelData:OxelPersistence = _oxelDataDic[oldGuid];
		if ( null == oxelData ) {
			Log.out( "OxelPersistenceCache.updateGuid - guid not found: " + oldGuid, Log.ERROR );
			return; }
		else {
			_oxelDataDic[oldGuid] = null;
			_oxelDataDic[newGuid] = oxelData;
		}
	}
	
	static private function request( $ode:OxelDataEvent ):void {   
		if ( null == $ode.modelGuid ) {
			Log.out( "OxelDataCache.modelDataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		
		//Log.out( "OxelDataCache.request guid: " + $ode.modelGuid, Log.DEBUG );
		var od:OxelPersistence = _oxelDataDic[$ode.modelGuid];
		if ( null == od ) {
			if ( _block.has( $ode.modelGuid ) )	
				return;
			_block.add( $ode.modelGuid );
				
			_loadingCount++;
			if ( true == Globals.online && $ode.fromTables )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid ) );
			else	
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ode.series, Globals.IVM_EXT, $ode.modelGuid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			OxelDataEvent.create( ModelBaseEvent.RESULT, $ode.series, $ode.modelGuid, od );
	}
	
	static private function generated( $ode:OxelDataEvent ):void  {
		add( 0, $ode.oxelData );
	}
	
	static private function deleteHandler( $ode:OxelDataEvent ):void {
		//Log.out( "OxelDataCache.deleteHandler $ode: " + $ode, Log.WARN );
		var od:OxelPersistence = _oxelDataDic[$ode.modelGuid];
		if ( null != od ) {
			_oxelDataDic[$ode.modelGuid] = null; 
			// TODO need to clean up eventually
			od = null;
		}
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid, null ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - OxelDataEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;

		var op:OxelPersistence = _oxelDataDic[$pe.guid];
		if ( null != op ) {
			// we already have it, publishing this results in dulicate items being sent to inventory window.
			OxelDataEvent.create( ModelBaseEvent.ADDED, $pe.series, $pe.guid, op );
			Log.out( "OxelPersistenceCache.loadSucceed - attempting to load duplicate OxelPersistence guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			op = new OxelPersistence( $pe.guid, $pe.dbo, null );
			add( $pe.series, op );
		} else if ( $pe.data ) {
			op = new OxelPersistence( $pe.guid, null, $pe.data as ByteArray );
			add( $pe.series, op );
		} else {
			Log.out( "OxelDataCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
		}
	}

	// This is the same as load succeed.
	static private function generateSucceed( $pe:PersistenceEvent):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		var od:OxelPersistence = new OxelPersistence( $pe.guid, null, $pe.data, true );
		add( $pe.series, od );
		Log.out( "OxelDataCache.generateSucceed " + $pe.toString(), Log.INFO );
	}

	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.loadFailed " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void  {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.loadNotFound " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		//OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
}
}