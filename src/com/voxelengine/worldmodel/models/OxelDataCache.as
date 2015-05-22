/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelBaseEvent;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.net.URLLoaderDataFormat;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class OxelDataCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _modelData:Dictionary = new Dictionary(false);
	
	public function OxelDataCache() {}
	
	static public function init():void {
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST, request );
		OxelDataEvent.addListener( ModelBaseEvent.CREATED, created );
		OxelDataEvent.addListener( ModelBaseEvent.DELETE, deleteHandler );
		// do I need ne of these?
		//ModelDataEvent.addListener( ModelBaseEvent.UPDATE, update );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	static private function deleteHandler( $mde:OxelDataEvent ):void {
		var md:OxelData = _modelData[$mde.modelGuid];
		if ( null != md ) {
			_modelData[$mde.modelGuid] = null; 
			md = null;
			// TODO need to clean up eventually
		}
		PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, $mde.series, Globals.BIGDB_TABLE_OXEL_DATA, $mde.modelGuid, null ) );
	}
	
	static private function created( $mde:OxelDataEvent):void 	{ add( 0, $mde.vmd ); }
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  modelData
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $mde:OxelDataEvent ):void 
	{   
		if ( null == $mde.modelGuid ) {
			Log.out( "ModelDataCache.modelDataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "ModelDataCache.request guid: " + $mde.modelGuid, Log.INFO );
		var mi:OxelData = _modelData[$mde.modelGuid]; 
		if ( null == mi ) {
			if ( true == Globals.online && $mde.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mde.series, Globals.BIGDB_TABLE_OXEL_DATA, $mde.modelGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mde.series, Globals.IVM_EXT, $mde.modelGuid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.RESULT, $mde.series, $mde.modelGuid, mi ) );
	}
	
	static private function add( $series:int, $md:OxelData ):void 
	{ 
		if ( null == $md || null == $md.guid ) {
			Log.out( "ModelDataCache.Add trying to add NULL modelData or guid", Log.WARN );
			return;
		}
		// check to make sure this is new data
		if ( null ==  _modelData[$md.guid] ) {
			//Log.out( "ModelDataCache.add adding: " + $md.modelGuid, Log.WARN );
			_modelData[$md.guid] = $md; 
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.ADDED, $series, $md.guid, $md ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			//Log.out( "ModelDataCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmd:OxelData = new OxelData( $pe.guid );
			if ( $pe.dbo )
				vmd.fromPersistance( $pe.dbo );
			else {
				// loading from file data
				vmd.compressedBA = $pe.data;
			}
				
			add( $pe.series, vmd );
		}
		else {
			Log.out( "ModelDataCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		Log.out( "ModelDataCache.loadFailed " + $pe.toString(), Log.WARN );
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "ModelDataCache.loadNotFound " + $pe.toString(), Log.WARN );
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
}
}