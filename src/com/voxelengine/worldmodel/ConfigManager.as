/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	
	import mx.utils.StringUtil;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.server.Network;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ConfigManager 
	{
		private var _showHelp:Boolean = true;
		private var _showEditMenu:Boolean = true;
		private var _showButtons:Boolean = true;
		private var _defaultRegionJson:Object
		
		public function get showHelp():Boolean { return _showHelp; }
		public function get showEditMenu():Boolean { return _showEditMenu; }
		public function get showButtons():Boolean { return _showButtons; }
		
		public function get defaultRegionJson():Object  { return _defaultRegionJson; }

		public function ConfigManager( $optionalGuid:String ):void 
		{
			if ( null != $optionalGuid ) {
				// need to log onto network. has Gui been initialized at this point?
				// this is the guid of a model to be loaded into a blank region.
				Log.out( "ConfigManager.new - individual model to be loaded: " + $optionalGuid, Log.DEBUG );
			}
			else {
				var _urlLoader:URLLoader = new URLLoader();
				Log.out( "ConfigManager.new - loading: " + Globals.appPath + "config.json", Log.DEBUG );
				_urlLoader.load(new URLRequest(Globals.appPath + "config.json"));
				_urlLoader.addEventListener(Event.COMPLETE, onConfigLoadedAction);
				_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorAction);			
			}
		}
		
		public function onConfigLoadedAction(event:Event):void
		{
			var jsonString:String = StringUtil.trim(String(event.target.data));
			_defaultRegionJson = JSON.parse(jsonString);
			var type:String = _defaultRegionJson.config.typeName;
			_showHelp = _defaultRegionJson.config.showHelp;
			_showEditMenu = _defaultRegionJson.config.showEditMenu;
			_showButtons = _defaultRegionJson.config.showButtons;
			
			Globals.g_app.addEventListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			TypeInfo.loadTypeData(type);
		}   
		
		private function onTypesLoaded( $e:LoadingEvent ):void
		{
			// This gives the engine a chance to load up the typeInfo file
			Globals.g_app.removeEventListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			if ( false ) {
				Globals.g_app.addEventListener(LoginEvent.LOGIN_SUCCESS, listenForLoginSuccess );
				Network.autoLogin( _defaultRegionJson.config.region.startingRegion );
			}
			else // loading local
				Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_CONFIG_COMPLETE, _defaultRegionJson.config.region.startingRegion ) );
		}
		
		private function listenForLoginSuccess( $event:LoginEvent ):void {
			Globals.g_app.removeEventListener(LoginEvent.LOGIN_SUCCESS, listenForLoginSuccess );
			RegionEvent.dispatch( new RegionEvent( RegionEvent.REQUEST_JOIN, _defaultRegionJson.config.region.startingRegion ) ); 
		}

		public function errorAction(e:IOErrorEvent):void
		{
			Log.out( "ConfigManager.errorAction - Config failed to load: " + e.toString(), Log.ERROR );
		}	
		
	} // ConfigManager
} // Package