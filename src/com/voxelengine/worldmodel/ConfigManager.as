/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.events.RegionEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	
	import mx.utils.StringUtil;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoadingEvent;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ConfigManager 
	{
		private var _showHelp:Boolean = true;
		private var _showEditMenu:Boolean = true;
		private var _showButtons:Boolean = true;
		
		public 	var _sr:String = "";
		
		public function get showHelp():Boolean { return _showHelp; }
		public function get showEditMenu():Boolean { return _showEditMenu; }
		public function get showButtons():Boolean { return _showButtons; }

		public function ConfigManager():void 
		{
			var _urlLoader:URLLoader = new URLLoader();
			Log.out( "ConfigManager.new - loading: " + Globals.appPath + "config.json", Log.INFO );
			_urlLoader.load(new URLRequest(Globals.appPath + "config.json"));
			_urlLoader.addEventListener(Event.COMPLETE, onConfigLoadedAction);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorAction);			
		}
		
		public function onConfigLoadedAction(event:Event):void
		{
			var jsonString:String = StringUtil.trim(String(event.target.data));
			var regionJson:Object = JSON.parse(jsonString);
			var type:String = regionJson.config.typeName;
			_showHelp = regionJson.config.showHelp;
			_showEditMenu = regionJson.config.showEditMenu;
			_showButtons = regionJson.config.showButtons;
			
			TypeInfo.loadTypeData(type);
			
			Globals.g_regionManager.request( regionJson.config.region.startingRegion )
			Globals.g_app.addEventListener( RegionEvent.REGION_STARTING_LOADED, onRegionStartingLoaded );
			Globals.g_app.addEventListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
		}   
		
		private function onTypesLoaded( $e:LoadingEvent ):void
		{
			Globals.g_app.removeEventListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			// used to load player here
		}

		private function onRegionStartingLoaded( $e:RegionEvent ):void
		{
			Globals.g_app.removeEventListener( RegionEvent.REGION_STARTING_LOADED, onRegionStartingLoaded );
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD, $e.regionId ) ); 
			if ( !Globals.player )
				Globals.createPlayer();
		}
		
		public function errorAction(e:IOErrorEvent):void
		{
			trace( "ConfigManager.errorAction: " + e.toString());
		}	
		
	} // ConfigManager
} // Package