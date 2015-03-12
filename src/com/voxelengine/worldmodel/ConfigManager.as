/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.events.PersistanceEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import org.flashapi.swing.Alert;
	
	import com.voxelengine.utils.StringUtils;

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
		static private function create( $startingModel:String ):void {
			if ( null == _s_currentInstance )
				new ConfigManager( $startingModel );
		}
		
		static private function destroy():void {
			ConfigManager._s_currentInstance = null;
		}
		
		static private var _s_currentInstance:ConfigManager = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }

		/////////////////////////////////////////////////////////////////////////////////////////
		
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
				Log.out( "ConfigManager.new - individual model to be loaded: " + $optionalGuid, Log.ERROR );
				// So we need to use autologin
				// then load the model into display, center, etc
			}
			else {
				PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );			
				PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFail );			
				PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, loadFail );			
				
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.APP_EXT, "config", null, null ) );
			}
		}
		
		private function loadSucceed(e:PersistanceEvent):void {
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );			
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_FAILED, loadFail );			
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_NOT_FOUND, loadFail );			
			
			_defaultRegionJson = JSON.parse( e.data );
			_showHelp = _defaultRegionJson.config.showHelp;
			_showEditMenu = _defaultRegionJson.config.showEditMenu;
			_showButtons = _defaultRegionJson.config.showButtons;
			
			LoadingEvent.addListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
			var typeInfoFile:String = _defaultRegionJson.config.typeName;
			//TypeInfo.loadTypeData( typeInfoFile );
			TypeInfo.load( typeInfoFile );
		}
		
		private function loadFail(e:PersistanceEvent):void {
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );			
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_FAILED, loadFail );			
			PersistanceEvent.removeListener( PersistanceEvent.LOAD_NOT_FOUND, loadFail );			
			var errorMsg:String = (e.data as String);
			Log.out( "ConfigManager.loadFail - error: " + errorMsg, Log.ERROR )
			// the Alert does not work here ???
			//(new Alert( "ConfigManager" ) ).display();
			//(new Alert( "ConfigManager.loadFail - error: " + errorMsg ) ).display();
			//var t:Alert = new Alert( "ConfigManager.loadFail" );
			//t.display();
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
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_CONFIG_COMPLETE, _defaultRegionJson.config.region.startingRegion ) );
		}
		
		private function listenForLoginSuccess( $event:LoginEvent ):void {
			LoginEvent.removeListener( LoginEvent.LOGIN_SUCCESS, listenForLoginSuccess );
			RegionEvent.dispatch( new RegionEvent( RegionEvent.JOIN, 0, _defaultRegionJson.config.region.startingRegion ) ); 
		}
	} // ConfigManager
} // Package