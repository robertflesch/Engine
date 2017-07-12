/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.utils.JSONUtil;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	//import org.flashapi.swing.Alert;
	
	import com.voxelengine.utils.StringUtils;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.events.PersistenceEvent;
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
		private var _defaultRegionJson:Object;
		
		public function get showHelp():Boolean { return _showHelp; }
		public function get showEditMenu():Boolean { return _showEditMenu; }
		public function get showButtons():Boolean { return _showButtons; }
		
		public function get defaultRegionJson():Object  { return _defaultRegionJson; }

		static private var _s_instance:ConfigManager;
		static public function get instance():ConfigManager {
			if ( null == _s_instance )
				_s_instance = new ConfigManager();		
			return _s_instance	
		}
		
		public function init( $optionalGuid:String ):void {
			if ( null != $optionalGuid ) {
				// need to log onto network. has Gui been initialized at this point?
				// this is the guid of a model to be loaded into a blank region.
				Log.out( "ConfigManager.new - individual model to be loaded: " + $optionalGuid, Log.ERROR );
				// So we need to use autologin
				// then load the model into display, center, etc
			}
		}
		
		public function ConfigManager( ):void 
		{
			PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
			PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, loadFail );
			PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );
			
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, 0, Globals.APP_EXT, "config", null, null ) );
		}
		
		private function loadSucceed(e:PersistenceEvent):void {
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_FAILED, loadFail );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );
			
			Log.out( "ConfigManager.loadSucceed: " + Globals.appPath + "config" + Globals.APP_EXT, Log.INFO );
			
			_defaultRegionJson = JSONUtil.parse( e.data, Globals.appPath + "config" + Globals.APP_EXT, "ConfigManager.loadSucceed" );
			if ( null == _defaultRegionJson ) {
				Log.out( "ConfigManager.loadSucceed - error parsing config: " + Globals.appPath + "config" + Globals.APP_EXT, Log.ERROR );
				return;
			}
			
			_showHelp = _defaultRegionJson.config.showHelp;
			_showEditMenu = _defaultRegionJson.config.showEditMenu;
			_showButtons = _defaultRegionJson.config.showButtons;
			
			LoadingEvent.addListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			var typeInfoFile:String = _defaultRegionJson.config.typeName;
			//TypeInfo.loadTypeData( typeInfoFile );
			TypeInfo.load( typeInfoFile );
		}
		
		private function loadFail(e:PersistenceEvent):void {
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_FAILED, loadFail );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );
			var errorMsg:String = (e.data as String);
			Log.out( "ConfigManager.loadFail - error: " + errorMsg + " file name and path: " + Globals.appPath + "config" + Globals.APP_EXT, Log.ERROR )
		}
		
		private function onTypesLoaded( $e:LoadingEvent ):void
		{
			// This gives the engine a chance to load up the typeInfo file
			LoadingEvent.removeListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			if ( false ) {
				LoginEvent.addListener( LoginEvent.LOGIN_SUCCESS, listenForLoginSuccess );
				Network.autoLogin( _defaultRegionJson.config.region.startingRegion );
			}
			else // loading local
				LoadingEvent.create( LoadingEvent.LOAD_CONFIG_COMPLETE, _defaultRegionJson.config.region.startingRegion );
		}
		
		private function listenForLoginSuccess( $event:LoginEvent ):void {
			LoginEvent.removeListener( LoginEvent.LOGIN_SUCCESS, listenForLoginSuccess );
			RegionEvent.create( RegionEvent.JOIN, 0, _defaultRegionJson.config.region.startingRegion );
		}
	} // ConfigManager
} // Package