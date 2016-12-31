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
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.IOErrorEvent;
import flash.events.HTTPStatusEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLLoaderDataFormat;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.utils.StringUtils;

/*
 * This class JUST loads objects from a URL (local or remote), it doesnt care what is in them.
 */
public class PersistURL
{
	// Used in importing of data
	static private var _filePath:String;

	static public function addEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST, load );
	}

	static private function isSupportedTable( $pe:PersistanceEvent ):Boolean {
		//if ( true == Globals.online )
		//	return;

		if ( Globals.REGION_EXT == $pe.table )
			_filePath = Globals.regionPath + $pe.guid + $pe.table;
		else if ( Globals.IVM_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( Globals.MODEL_INFO_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( Globals.APP_EXT == $pe.table )
			_filePath = Globals.appPath + $pe.guid + $pe.table;
		else if ( Globals.ANI_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( Globals.AMMO_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( Globals.SOUND_EXT == $pe.table )
			_filePath = Globals.soundPath + $pe.guid + $pe.table;

		else
			return false;

		return true;
	}

	static private function load( $pe:PersistanceEvent ):void {
		if ( !isSupportedTable( $pe ) ) {
			//Log.out("PersistURL.load - EXTENSION IS NOT SUPPORTED EXT:" + $pe.table , Log.ERROR );
			//PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
			return;
		}

		//Log.out( "PersistURL.load - file: " + _filePath );

		var urlLoader:URLLoader = new URLLoader();
		configureListeners(urlLoader);
		urlLoader.dataFormat = $pe.format;
		urlLoader.addEventListener(Event.COMPLETE, loadSuccess );
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		try {
			urlLoader.load(new URLRequest( _filePath ));
		} catch (error:Error) {
			Log.out("PersistURL.load - Unable to load requested document." + error.getStackTrace(), Log.WARN );
		}


		function loadSuccess(event:Event):void {

			//Log.out( "PersistURL.loadSuccess - guid: " + $pe.guid + $pe.table, Log.DEBUG );
			if ( URLLoaderDataFormat.BINARY == $pe.format ) {
				var ba:ByteArray = event.target.data;
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $pe.guid, null, ba, $pe.format, $pe.other ) );
			}
			else {

				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $pe.guid, null, StringUtils.trim(event.target.data), $pe.format, $pe.other ) );
			}
		}

		function loadError(event:IOErrorEvent):void {
			var errorMsg:String = "PersistURL.loadError - event: " + event.toString() + "  filePath: " + _filePath;
			//Log.out( errorMsg, Log.WARN );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, 0, $pe.table, $pe.guid, null, errorMsg, $pe.format, $pe.other ) );
		}

		function configureListeners(dispatcher:URLLoader):void {
			//dispatcher.addEventListener(Event.OPEN, openHandler);
			//dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			//dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
		}

		function openHandler(event:Event):void {
			Log.out("PersistURL.openHandler guid: " + $pe.guid + $pe.table + " event: " + event, Log.DEBUG);
		}

		function progressHandler(event:ProgressEvent):void {
			Log.out("PersistURL.progressHandler guid: " + $pe.guid + $pe.table + "  loaded:" + event.bytesLoaded + " total: " + event.bytesTotal, Log.DEBUG );
		}

		function securityErrorHandler(event:SecurityErrorEvent):void {
			Log.out("PersistURL.securityErrorHandler: guid: " + $pe.guid + $pe.table + "  event " + event, Log.WARN );
		}

		function httpStatusHandler(event:HTTPStatusEvent):void {
			Log.out( "PersistURL.httpStatusHandler: " + event, Log.DEBUG );
		}
	}
}	
}
