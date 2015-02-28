/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.persistance 
{
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLLoaderDataFormat;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.utils.StringUtils;

/*
 * This class JUST loads the objects from the database, it doesnt care what is in them.
 */
public class PersistLocal
{
	static private var _filePath:String;
	
	static public function addEvents():void {
//		Log.out( "PersistLocal.addEvents", Log.WARN );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST, load );
	}
	
	static private function isSupportedTable( $pe:PersistanceEvent ):Boolean {
		//if ( true == Globals.online )
		//	return;
		
		if ( Globals.REGION_EXT == $pe.table )
			_filePath = Globals.regionPath + $pe.guid + $pe.table
		else if ( Globals.IVM_EXT == $pe.table )	
			_filePath = Globals.modelPath + $pe.guid + $pe.table
		else if ( Globals.MODEL_INFO_EXT == $pe.table )	
			_filePath = Globals.modelPath + $pe.guid + $pe.table
		else
			return false;
		
		return true;
	}
	
	static private function load( $pe:PersistanceEvent ):void { 
		
		if ( !isSupportedTable( $pe ) )
			return;
			
		Log.out( "PersistLocal.load - file: " + _filePath, Log.DEBUG );
		
		var urlLoader:URLLoader = new URLLoader();
		urlLoader.load(new URLRequest( _filePath ));
		urlLoader.dataFormat = $pe.format;
		urlLoader.addEventListener(Event.COMPLETE, loadSuccess );
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);			
		

		function loadSuccess(event:Event):void {
			
			Log.out( "PersistLocal.loadSuccess - event: " + event.toString(), Log.DEBUG );
			if ( URLLoaderDataFormat.BINARY == $pe.format ) {
				var ba:ByteArray = event.target.data;			
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.table, $pe.guid, null, ba ) );
			}
			else {
				
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.table, $pe.guid, null, StringUtils.trim(event.target.data) ) );
			}
		}       

		function loadError(event:IOErrorEvent):void {
			Log.out( "PersistLocal.loadError - event: " + event.toString(), Log.WARN );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}	
	}
}	
}
