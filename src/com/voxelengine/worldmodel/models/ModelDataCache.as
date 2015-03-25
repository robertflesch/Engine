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
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class ModelDataCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _modelData:Dictionary = new Dictionary(false);
	
	public function ModelDataCache() {}
	
	static public function init():void {
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST, request );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  modelData
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $mie:ModelDataEvent ):void 
	{   
		if ( null == $mie.modelGuid ) {
			Log.out( "ModelDataCache.modelDataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "ModelDataCache.request guid: " + $mie.modelGuid, Log.INFO );
		var mi:ModelData = _modelData[$mie.modelGuid]; 
		if ( null == mi ) {
			if ( true == Globals.online && $mie.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.DB_TABLE_MODELS_DATA, $mie.modelGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.IVM_EXT, $mie.modelGuid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.RESULT, $mie.series, $mie.modelGuid, mi ) );
	}
	
	static private function add( $pe:PersistanceEvent, $md:ModelData ):void 
	{ 
		if ( null == $md || null == $pe.guid ) {
			Log.out( "ModelDataCache.modelDataAdd trying to add NULL modelData or guid", Log.WARN );
			return;
		}
		// check to make sure this is new data
		if ( null ==  _modelData[$pe.guid] ) {
			_modelData[$pe.guid] = $md; 
			ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, $md ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			Log.out( "ModelDataCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmd:ModelData = new ModelData( $pe.guid );
			if ( $pe.dbo )
				vmd.fromPersistance( $pe.dbo );
			else {
				// loading from file data
				var ba:ByteArray = $pe.data;
				try {  ba.uncompress(); }
				catch (error:Error) { ; }
				ba.position = 0;
				vmd.ba = ba;
			}
				
			add( $pe, vmd );
		}
		else {
			Log.out( "ModelDataCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataCache.loadFailed " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataCache.loadNotFound " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
	}
	
}
}