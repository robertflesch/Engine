/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.persistance 
{
import com.voxelengine.worldmodel.animation.AnimationSound;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

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
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.utils.StringUtils;

import playerio.GameFS;
import playerio.PlayerIO;

/*
 * This class JUST loads objects from a URL (local or remote), it doesnt care what is in them.
 */
public class PersistURL
{
	// Used in importing of data
	static private var _filePath:String;

	static public function addEvents():void {
		PersistenceEvent.addListener( PersistenceEvent.LOAD_REQUEST, load );
	}

	static private function isSupportedTable( $pe:PersistenceEvent ):Boolean {

		if ( Globals.REGION_EXT == $pe.table )
			_filePath = Globals.regionPath + $pe.guid + $pe.table;
		else if ( Globals.IVM_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( Globals.MODEL_INFO_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
        else if ( Globals.LANG_EXT == $pe.table )
            _filePath = $pe.guid;
		else if ( Globals.APP_EXT == $pe.table )
			_filePath = Globals.appPath + $pe.guid + $pe.table;
		else if ( Globals.ANI_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.other + "/" + $pe.guid + $pe.table;
		else if ( Globals.AMMO_EXT == $pe.table )
			_filePath = Globals.modelPath + $pe.guid + $pe.table;
		else if ( AnimationSound.SOUND_EXT == $pe.table )
			_filePath = Globals.soundPath + $pe.guid + $pe.table;
        else if ( Globals.APP_XML == $pe.table )
            _filePath = Globals.appPath + "assets/languages/lang_en/" + $pe.guid + $pe.table;

		else
			return false;

		return true;
	}

	static private function load( $pe:PersistenceEvent ):void {
		if ( !isSupportedTable( $pe ) ) {
			//Log.out("PersistURL.load - EXTENSION IS NOT SUPPORTED EXT:" + $pe.table , Log.ERROR );
			//PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
			return;
		}

		//Log.out( "PersistURL.load - file: " + _filePath );
		var urlLoader:URLLoader = new URLLoader();
		configureListeners(urlLoader);
		urlLoader.dataFormat = $pe.format;
		urlLoader.addEventListener(Event.COMPLETE, loadSuccess );
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
        var resolvedFilePath:String;
		try {
			if ( ModelMakerImport.isImporting ) {
				resolvedFilePath = "E:/dev/VoxelVerse/Resources/bin" + _filePath;
                urlLoader.load( new URLRequest( resolvedFilePath ) );
            }
			else if ( "/" == Globals.appPath  ) {
                var fs:GameFS = PlayerIO.gameFS(Globals.GAME_ID);
                resolvedFilePath = fs.getUrl(_filePath);
                urlLoader.load(new URLRequest(resolvedFilePath));
            } else {
                Log.out("PersistURL.load - Where am I trying to load from? " + _filePath, Log.WARN );

			}

		} catch (error:Error) {
			Log.out("PersistURL.load - Unable to load requested document." + error.getStackTrace(), Log.WARN );
		}


		function loadSuccess(event:Event):void {
			//Log.out( "PersistURL.loadSuccess - guid: " + $pe.guid + $pe.table + "  from location: " + resolvedFilePath, Log.DEBUG );
			if ( URLLoaderDataFormat.BINARY == $pe.format )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $pe.guid, null, event.target.data, $pe.format, $pe.other ) );
			else
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $pe.guid, null, StringUtils.trim(event.target.data), $pe.format, $pe.other ) );
		}

		function loadError(event:IOErrorEvent):void {
            Log.out( "PersistURL.loadError - guid: " + $pe.guid + $pe.table + "  from location: " + resolvedFilePath + "  event: " + event.toString(), Log.WARN );
			var errorMsg:String = "PersistURL.loadError - event: " + event.toString() + "  filePath: " + _filePath;
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, 0, $pe.table, $pe.guid, null, errorMsg, $pe.format, $pe.other ) );
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
