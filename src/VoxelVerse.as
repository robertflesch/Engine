/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ErrorEvent;	
	import flash.events.UncaughtErrorEvent;	
	import flash.external.ExternalInterface;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.GUIEvent;
	import com.voxelengine.events.InventoryEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.LightEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.GUI.VoxelVerseGUI;
	import com.voxelengine.GUI.WindowSplash;
	import com.voxelengine.renderer.Renderer;
	import com.voxelengine.persistance.Persistance;
	import com.voxelengine.pools.PoolManager;
	import com.voxelengine.worldmodel.ConfigManager;
	import com.voxelengine.worldmodel.MemoryManager;
	import com.voxelengine.worldmodel.MouseKeyboardHandler;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.RegionManager;
	import com.voxelengine.worldmodel.inventory.InventoryManager;
	import com.voxelengine.worldmodel.tasks.lighting.LightAdd;
	import com.voxelengine.worldmodel.tasks.lighting.LightRemove;
	
	public class VoxelVerse extends Sprite 
	{
		private var _timePrevious:int = getTimer();
		private var _configManager:ConfigManager;
		private var _poolManager:PoolManager;
		
		private var _showConsole:Boolean;
		private var _toolOrBlockEnabled:Boolean;
		private var _editing: Boolean = true;
		private var _displayGuid:String;
		
		public function get editing():Boolean { return _editing; }
		public function set editing(val:Boolean):void { _editing = val; }
		public function get toolOrBlockEnabled():Boolean { return _toolOrBlockEnabled; }
		public function set toolOrBlockEnabled(val:Boolean):void { _toolOrBlockEnabled = val; }
		public function get configManager():ConfigManager { return _configManager; }
		
		public function get showConsole():Boolean { return _showConsole; }
		public function set showConsole(value:Boolean):void { _showConsole = value; }

		// Main C'tor for project
		public function VoxelVerse():void {
			addEventListener(Event.ADDED_TO_STAGE, init);
			Globals.g_app = this;
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			var parameters:Object = stage.loaderInfo.parameters;
			if ( parameters.guid ) {
				Log.out( "VoxelVerse.init - single model found: " + parameters.guid, Log.DEBUG );
				//_displayGuid = parameters.guid;			
			}
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent;}")).toLowerCase();			
			
			// expect an exception to be thrown and caught here, the best way I know of to find out of we are in debug or release mode
			try
			{
				var result : Boolean = new Error().getStackTrace().search(/:[0-9]+]$/m) > -1;
				Globals.g_debug = result;
			}
			catch ( error:Error )
			{
				Globals.g_debug = false;
			}
			
			try
			{
				// This doesnt work in chrome, so I need someway to detect chrome and do it differently
				// Globals.appPath = "file:///C:/dev/VoxelVerse/resources/bin/";
				var urlPath:String = ExternalInterface.call("window.location.href.toString");
				Log.out( "VoxelVerse.swf loaded from: " + urlPath, Log.DEBUG );
				var index:int = urlPath.indexOf( "index.html" );
				if ( -1 == index )
				{
					index = urlPath.lastIndexOf( "/" );
					var gap:String = urlPath.substr( 0, index + 1 );
					Globals.appPath = gap;
				}
				else {
					//if ( Globals.g_debug ) 
						Globals.appPath = urlPath.substr( 0, index );
				}
				Log.out( "VoxelVerse.init set appPath to: " + Globals.appPath );
			}
			catch ( error:Error )
			{
				Log.out("VoxelVerse.init - ExternalInterface not found, using default location", Log.ERROR, error );
				//Globals.appPath = 
			}
			
			Globals.g_renderer.init( stage );
			// adds handlers for persistance of regions
			Persistance.addEventHandlers();
			
			WindowSplashEvent.addListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded);
			
			VoxelVerseGUI.currentInstance.init();
			
			WindowSplash.init();
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) );
			
				
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		}
		
		private function addStaticListeners():void {
			addEventListener( LightEvent.ADD, LightAdd.handleLightEvents );
			addEventListener( LightEvent.SOLID_TO_ALPHA, LightAdd.handleLightEvents );
			addEventListener( LightEvent.ALPHA_TO_SOLID, LightRemove.handleLightEvents );
			addEventListener( LightEvent.REMOVE, LightRemove.handleLightEvents );
		}

		// after the splash and config have been loaded
		public function onSplashLoaded( event : WindowSplashEvent ):void	{
			
			//Log.out( "VoxelVerse.onSplashLoaded" );
			// TODO I dont like that some objects are created in globals, others are created here - RSF
			WindowSplashEvent.removeListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded);
			
			Globals.g_regionManager = new RegionManager();
			_configManager = new ConfigManager( _displayGuid );
			_poolManager = new PoolManager();
			
			addEventListener(Event.ENTER_FRAME, enterFrame);
			addEventListener(Event.DEACTIVATE, deactivate);
			addEventListener(Event.ACTIVATE, activate);
			
			//Log.out( "VoxelVerse.onSplashLoaded - stage.addEventListener" );
//			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
			stage.addEventListener(MouseEvent.RIGHT_CLICK, onMouseRightClick);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseDownRight);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseUpRight);
			
			VoxelVerseGUI.currentInstance.buildGUI();	
		}

		private function enterFrame(e:Event):void {
			//Log.out( "VoxelVerse.enterFrame" );
			const timeEntered:int = getTimer();
			var elapsed:int = timeEntered - _timePrevious;
			_timePrevious = timeEntered;
			
			MemoryManager.update();
			
			var timeUpdate:int = getTimer();
			Globals.g_regionManager.update( elapsed );
			timeUpdate = getTimer() - timeUpdate;
			
			if ( showConsole )
				toggleConsole();
				
			var timeRender:int = getTimer();
			Globals.g_renderer.render();
			timeRender = getTimer() - timeRender;
				
			if ( ( 10 < timeRender || 10 < timeUpdate ) && Globals.active )	
				Log.out( "VoxelVerse.enterFrame - render: " + timeRender + "  timeUpdate: " + timeUpdate + "  total time: " +  + ( getTimer() - timeEntered ) + "  time to get back to app: " + elapsed, Log.INFO );
			_timePrevious = getTimer();
		}
		
		private function deactivate(e:Event):void 
		{
			//Log.out( "VoxelVerse.deactive event", Log.WARN );
			if ( Globals.active )
				deactivateApp();
		}
		
		private function activate(e:Event):void 
		{
			//Log.out( "VoxelVerse.activate event" );
			activateApp();
		}
		
		/**
		 *  Called when the mouse leaves the app
		 *  by leaving the app, the active is set to false
		 *  and the mouse view is turned off.
		 *  This allow the app to not pick up any other mouse or keyboard
		 *  activity when app is not active
		 * 
		 * 	@param e 	Event Object generated by system
		 */
		public function mouseLeave( e:Event ):void
		{
			//Log.out( "VoxelVerse.mouseLeave event" );
			if ( Globals.active )
				deactivateApp();
		}
		
		private function activateApp():void {
			
			if ( false == Globals.active ) {
			//	Log.out( "VoxelVerse.activateApp - setting active = TRUE" );
				Globals.active = true;
				Globals.clicked = true;
				VoxelVerseGUI.currentInstance.crossHairActive();
				
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
				
				dispatchEvent( new GUIEvent( GUIEvent.APP_ACTIVATE ) );
			}
			//else
				//Log.out( "VoxelVerse.activateApp - ignoring" );
		}

		private function deactivateApp():void {
			
			//Log.out( "VoxelVerse.deactivateApp", Log.WARN );
			if ( true == Globals.active ) {
				//Log.out( "VoxelVerse.deactivateApp with active app", Log.WARN );
				Globals.active = false;
				Globals.mouseView = false;
				Globals.clicked = false;
				VoxelVerseGUI.currentInstance.crossHairInactive();
				
				MemoryManager.update();
				MouseKeyboardHandler.reset();
				
				// one way to wake us back up is thru the mouse click
				stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
					

				if ( Globals.online ) {
					//Log.out( "VoxelVerse.deactivateApp - NOT SAVING REGION AND INVENTORY", Log.WARN );
					RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid ) );
					InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_SAVE_REQUEST, null, null ) );
				}
				
				dispatchEvent( new GUIEvent( GUIEvent.APP_DEACTIVATE ) );
			}
			//else
			//	Log.out( "VoxelVerse.activateApp - ignoring", Log.WARN );
		}
		
		private function mouseDown(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		private function mouseUp(e:MouseEvent):void 
		{
			//Log.out( "VoxelVerse.mouseUp event" );
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			activateApp();
		}
		
		private function mouseDownRight(e:MouseEvent):void {
//			Log.out("VoxelVerse.mouseDownRight" );
			Globals.mouseView = true;
		}
		
		private function mouseUpRight(e:MouseEvent):void {
//			Log.out("VoxelVerse.mouseUpRight" );
			Globals.mouseView = false;
		}
		
		private function onMouseRightClick(e:MouseEvent):void 
		{
			//trace ( "VoxelVerse.onMouseRightClick - Right click functions enabled" )
		}
		
		
		private function toggleConsole():void 
		{
			showConsole = false;
			if ( Log.showing )
				Log.hide();
			else
				Log.show();
		}
		
		private var _shiftDown:Boolean;
		private var _controlDown:Boolean;
		private function keyDown(e:KeyboardEvent):void 
		{
			switch (e.keyCode) {
				//case Keyboard.BACKQUOTE:
				case Keyboard.SHIFT:
					_shiftDown = true;
					break;
				case Keyboard.CONTROL:
					_controlDown = true;
					break;
				case Keyboard.ENTER:
					// trying to stop the BACKQUOTE from getting to the doomsday console.
					//e.stopImmediatePropagation();
					if ( _controlDown )
						showConsole = true;
					break;
			}
		}
		
		private function keyUp(e:KeyboardEvent):void 
		{
			switch (e.keyCode) {
				//case Keyboard.BACKQUOTE:
				case Keyboard.SHIFT:
					_shiftDown = false;
					break;
				case Keyboard.CONTROL:
					_controlDown = false;
					break;
			}
		}
		////////////////////////////
        
        private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
        {
            if (event.error is Error)
            {
                var error:Error = event.error as Error;
                Log.out( "VoxelVerse.uncaughtErrorHandler name: " + error.name + " message: " + error.message + "  stackTrace: " + error.getStackTrace(), Log.ERROR )
            }
            else if (event.error is ErrorEvent)
            {
                var errorEvent:ErrorEvent = event.error as ErrorEvent;
                Log.out( "VoxelVerse.uncaughtErrorHandler name: " + error.name + " message: " + error.message + "  stackTrace: " + error.getStackTrace(), Log.ERROR )
            }
            else
            {
                Log.out( "VoxelVerse.uncaughtErrorHandler something was caught: " + event.toString(), Log.WARN )
            }
        }
	}
}