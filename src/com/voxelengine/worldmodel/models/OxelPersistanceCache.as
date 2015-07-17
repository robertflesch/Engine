/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.net.URLLoaderDataFormat;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class OxelPersistanceCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _loadingCount:int;
	static private var _oxelDataDic:Dictionary = new Dictionary(false);
	static private var _block:Block = new Block();
	
	public function OxelPersistanceCache() {}
	
	static public function init():void {
		// These are the events that this object listens for.
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST, 				request );
		OxelDataEvent.addListener( ModelBaseEvent.GENERATION, 			generated );
		OxelDataEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		OxelDataEvent.addListener( ModelBaseEvent.UPDATE_GUID, 			updateGuid );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	static private function add( $series:int, $od:OxelPersistance ):void { 
		if ( null == $od || null == $od.guid ) {
			Log.out( "OxelDataCache.Add trying to add NULL OxelData or guid", Log.WARN );
		} else if ( null == _oxelDataDic[$od.guid] ) { // check to make sure this is new data
			//Log.out( "OxelDataCache.add adding: " + $od.modelGuid, Log.INFO );
			_oxelDataDic[$od.guid] = $od; 
			if ( _block.has( $od.guid ) )
				_block.clear( $od.guid )
			_loadingCount--;
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.ADDED, $series, $od.guid, $od ) );
			if ( 0 == _loadingCount ) {
				//Log.out( "OxelPersistanceCache.add - done loading oxels: " + $od.guid, Log.WARN );
				RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid ) );
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
		var oxelData:OxelPersistance = _oxelDataDic[oldGuid];
		if ( null == oxelData ) {
			Log.out( "OxelPersistanceCache.updateGuid - guid not found: " + oldGuid, Log.ERROR );
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
		
		Log.out( "OxelDataCache.request guid: " + $ode.modelGuid, Log.DEBUG );
		var od:OxelPersistance = _oxelDataDic[$ode.modelGuid]; 
		if ( null == od ) {
			if ( _block.has( $ode.modelGuid ) )	
				return;
			else
				_block.add( $ode.modelGuid );
				
			_loadingCount++;
			if ( true == Globals.online && $ode.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ode.series, Globals.IVM_EXT, $ode.modelGuid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.RESULT, $ode.series, $ode.modelGuid, od ) );
	}
	
	static private function generated( $ode:OxelDataEvent ):void  {
		add( 0, $ode.oxelData );
	}
	
	static private function deleteHandler( $ode:OxelDataEvent ):void {
		Log.out( "OxelDataCache.deleteHandler $ode: " + $ode, Log.WARN );
		var od:OxelPersistance = _oxelDataDic[$ode.modelGuid];
		if ( null != od ) {
			_oxelDataDic[$ode.modelGuid] = null; 
			// TODO need to clean up eventually
			od = null;
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid, null ) );
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - OxelDataEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function loadSucceed( $pe:PersistanceEvent):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			//Log.out( "OxelDataCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var od:OxelPersistance = new OxelPersistance( $pe.guid );
			if ( !$pe.dbo ) {
				var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_OXEL_DATA, "0", "0", 0, true, null );
				dbo.data = new Object();
				dbo.data.ba = $pe.data;
				od.fromObjectImport( dbo );
				// On import mark it as changed.
				od.changed = true;
			}
			else
				od.fromObject( $pe.dbo );
				
			add( $pe.series, od );
			
			//if ( _block.has( $pe.guid ) )
				//_block.clear( $pe.guid )
		}
		else {
			Log.out( "OxelDataCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		Log.out( "OxelDataCache.loadFailed " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void  {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.loadNotFound " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
}
}