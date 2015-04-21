/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.utils.JSONUtil;
import flash.utils.Dictionary;
import org.flashapi.swing.Alert;

import com.voxelengine.utils.StringUtils;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class ModelInfoCache
{
	// this only loaded ModelInfo from the local files system.
	// for the online system this information is embedded in the data segment.
	static private var _modelInfo:Dictionary = new Dictionary(false);
	
	public function ModelInfoCache() {}
	
	static public function init():void {
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST, 			request );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	static private function request( $mie:ModelInfoEvent ):void {   
		if ( null == $mie.modelGuid ) {
			Log.out( "ModelInfoManager.modelInfoRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "ModelInfoManager.modelInfoRequest guid: " + $mie.modelGuid, Log.INFO );
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( null == mi )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.MODEL_INFO_EXT, $mie.modelGuid ) );
		else
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.RESULT, $mie.series, $mie.modelGuid, mi ) );
	}
	
	static private function add( $pe:PersistanceEvent, $mi:ModelInfo ):void { 
		if ( null == $mi || null == $pe.guid ) {
			Log.out( "ModelInfoManager.modelInfoAdd trying to add NULL modelInfo or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _modelInfo[$pe.guid] ) {
			//Log.out( "ModelInfoManager.modelInfoAdd vmm: " + $vmm.toString(), Log.WARN );
			_modelInfo[$pe.guid] = $mi; 
			
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, $mi ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void {
		if ( Globals.MODEL_INFO_EXT != $pe.table )
			return;
		//Log.out( "ModelInfoManager.modelInfoLoadSucceed guid: " + $pe.guid, Log.INFO );
		if ( $pe.data ) {
				var fileData:String = String( $pe.data );
				var modelInfoJson:String = StringUtils.trim(fileData);
				// modelInfoJson = decodeURI(fileData);
				//Log.out( "ModelInfoCache.loadSucceed - STRING modelInfo: " + modelInfoJson,	Log.WARN );
				var jsonResult:Object = JSONUtil.parse( modelInfoJson, $pe.guid + $pe.table, "ModelInfoCache.loadSucceed" );
				if ( null == jsonResult ) {
					(new Alert( "VoxelVerse - Error Parsing: " + $pe.guid + $pe.table, 500 ) ).display();
					ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
					return;
				}
				
				var mi:ModelInfo = new ModelInfo();
				mi.initJSON( $pe.guid, jsonResult );
				//ModelEvent.dispatch( new ModelEvent( ModelEvent.INFO_LOADED, guid ) );
				add( $pe, mi );
		}
		else {
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void {
		if ( Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoManager.modelInfoLoadFailed PersistanceEvent: " + $pe.toString(), Log.ERROR );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void {
		if ( Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoManager.loadNotFound PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
}
}