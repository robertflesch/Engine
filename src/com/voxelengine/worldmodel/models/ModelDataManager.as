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
public class ModelDataManager
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _modelData:Dictionary = new Dictionary(false);
	
	public function ModelDataManager() {}
	
	static public function init():void {
		ModelDataEvent.addListener( ModelDataEvent.REQUEST, request );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, loadNotFound );		
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
		var mi:VoxelModelData = _modelData[$mie.guid]; 
		if ( null == mi ) {
			if ( true == Globals.online )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, Globals.DB_TABLE_MODELS_DATA, $mie.guid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, Globals.IVM_EXT, $mie.guid, null, null, URLLoaderDataFormat.BINARY ) );
		}
		else
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.ADDED, $mie.guid, mi ) );
	}
	
	static private function modelDataAdd( $guid:String, $mi:VoxelModelData ):void 
	{ 
		if ( null == $mi || null == $guid ) {
			Log.out( "ModelDataManager.modelDataAdd trying to add NULL modelData or guid", Log.WARN );
			return;
		}
		// check to make sure this is new data
		if ( null ==  _modelData[$guid] ) {
			_modelData[$guid] = $mi; 
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.ADDED, $guid, $mi ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		if ( $pe.data ) {
			Log.out( "ModelDataManager.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmd:VoxelModelData = new VoxelModelData( $pe.guid, null, $pe.data );
			modelDataAdd( $pe.guid, vmd );
		}
		else {
			Log.out( "ModelDataManager.loadSucceed ERROR NO DBO " + $pe.toString(), Log.ERROR );
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.FAILED, null, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataManager.loadFailed " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.FAILED, null, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "ModelDataManager.loadNotFound " + $pe.toString(), Log.ERROR );
		ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.FAILED, null, null ) );
	}
	
}
}