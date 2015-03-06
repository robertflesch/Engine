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
		if ( null == $mie.guid ) {
			Log.out( "ModelDataManager.modelDataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "ModelDataManager.request guid: " + $mie.guid, Log.INFO );
		var mi:ModelData = _modelData[$mie.guid]; 
		if ( null == mi ) {
			if ( true == Globals.online && $mie.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.DB_TABLE_MODELS_DATA, $mie.guid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.IVM_EXT, $mie.guid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.RESULT, $mie.series, $mie.guid, mi ) );
	}
	
	static private function add( $pe:PersistanceEvent, $md:ModelData ):void 
	{ 
		if ( null == $md || null == $pe.guid ) {
			Log.out( "ModelDataManager.modelDataAdd trying to add NULL modelData or guid", Log.WARN );
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
			Log.out( "ModelDataManager.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmd:ModelData = new ModelData( $pe.guid );
			if ( $pe.dbo )
				vmd.fromPersistance( $pe.dbo );
			else
				vmd.ba = $pe.data;
			add( $pe, vmd );
		}
		else {
			Log.out( "ModelDataManager.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataManager.loadFailed " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataManager.loadNotFound " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
	}
	
}
}