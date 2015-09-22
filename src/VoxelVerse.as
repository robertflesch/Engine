/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
	import com.voxelengine.events.AnimationEvent
	import flash.display.Sprite
	import flash.display.StageAlign
	import flash.display.StageScaleMode
	import flash.events.Event
	import flash.events.KeyboardEvent
	import flash.events.MouseEvent
	import flash.events.ErrorEvent	
	import flash.events.UncaughtErrorEvent	
	import flash.system.LoaderContext
	import flash.system.Security
	import flash.system.SecurityDomain
	import flash.system.ApplicationDomain	
	import flash.ui.Keyboard
	import flash.utils.getTimer
	
	import com.voxelengine.Log
	import com.voxelengine.Globals
	import com.voxelengine.events.GUIEvent
	import com.voxelengine.events.InventoryEvent
	import com.voxelengine.events.RegionEvent
	import com.voxelengine.events.ModelBaseEvent
	import com.voxelengine.events.ModelInfoEvent
	import com.voxelengine.GUI.VoxelVerseGUI
	import com.voxelengine.worldmodel.RegionManager
	import com.voxelengine.worldmodel.MemoryManager
	import com.voxelengine.worldmodel.MouseKeyboardHandler
	import com.voxelengine.worldmodel.Region
	
	public class VoxelVerse extends Sprite 
	{
		private var _timePrevious:int = getTimer()
		
		private var _showConsole:Boolean
		public function get showConsole():Boolean { return _showConsole }
		public function set showConsole(value:Boolean):void { _showConsole = value }

		// Main C'tor for project
		public function VoxelVerse():void {
			addEventListener(Event.ADDED_TO_STAGE, init)
			Globals.g_app = this
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init)
			
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler)
			
			stage.scaleMode = StageScaleMode.NO_SCALE
			stage.align = StageAlign.TOP_LEFT
			
			VVInitializer.initialize( stage )
			
			//var parameters:Object = stage.loaderInfo.parameters
			//if ( parameters.guid ) {
				//Log.out( "VVInitializer.initialize - single model found: " + parameters.guid, Log.DEBUG )
				//new LoadSynchronizer( parameters.guid )
			//}
			//else
				new StartupSynchronizer()
		}
		
		// after the splash and config have been loaded
		public function readyToGo():void	{
			//Log.out( "<===============VoxelVerse.readyToGo - ENTER", Log.DEBUG )
			
			addEventListener(Event.ENTER_FRAME, enterFrame)
			addEventListener(Event.DEACTIVATE, deactivate)
			addEventListener(Event.ACTIVATE, activate)
			
			//Log.out( "VoxelVerse.onSplashLoaded - stage.addEventListener" )
//			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown)
//			stage.addEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick) // Not supporting right click
			stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave)
//			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseDownRight)
//			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseUpRight)
			
			// These two should be the same
			// https://gamesnet.yahoo.net/forum/viewtopic.php?f=33&t=35896&sid=1f0b0c5bef7f97c6961760b6a3418c69
			// for reference
			//Security.loadPolicyFile( "http://cdn.playerio.com/crossdomain.xml" )
			//Security.loadPolicyFile( "https://content.playerio.com/crossdomain.xml" )
			//var ctxt:LoaderContext = new LoaderContext( true )
			//ctxt.securityDomain = SecurityDomain.currentDomain
			//Security.allowDomain( "*" )
			VoxelVerseGUI.currentInstance.buildGUI()	
			//Log.out( "VoxelVerse.readyToGo", Log.DEBUG )
		}
		
		private function mouseDown(e:MouseEvent):void {
			//Log.out( "VoxelVerse.mouseDown", Log.WARN )
//			if ( Globals.openWindowCount || !Globals.clicked || e.ctrlKey || !Globals.active )
//				return
		}
		
		
		private function enterFrame(e:Event):void {
			//Log.out( "VoxelVerse.enterFrame" )
			const timeEntered:int = getTimer()
			var elapsed:int = timeEntered - _timePrevious
			_timePrevious = timeEntered
			
			MemoryManager.update()
			
			var timeUpdate:int = getTimer()
			
			RegionManager.instance.update( elapsed )
			timeUpdate = getTimer() - timeUpdate
			
			if ( showConsole )
				toggleConsole()
				
			var timeRender:int = getTimer()
			Globals.g_renderer.render()
			timeRender = getTimer() - timeRender
				
			//if ( ( 10 < timeRender || 10 < timeUpdate ) && Globals.active )	
			//	Log.out( "VoxelVerse.enterFrame - render: " + timeRender + "  timeUpdate: " + timeUpdate + "  total time: " +  + ( getTimer() - timeEntered ) + "  time to get back to app: " + elapsed, Log.INFO )
			_timePrevious = getTimer()
		}
		
		private function deactivate(e:Event):void 
		{
			//Log.out( "VoxelVerse.deactive event", Log.WARN )
			if ( Globals.active )
				deactivateApp()
		}
		
		private function activate(e:Event):void 
		{
			//Log.out( "VoxelVerse.activate event", Log.WARN )
			activateApp()
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
			//Log.out( "VoxelVerse.mouseLeave event" )
			if ( Globals.active )
				deactivateApp()
		}
		
		private function activateApp():void {
			
			if ( false == Globals.active ) {
				//Log.out( "VoxelVerse.activateApp - setting active = TRUE" )
				Globals.active = true
				Globals.clicked = true
				VoxelVerseGUI.currentInstance.crossHairActive()
				
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown)
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUp)
				
//				GUIEvent.dispatch( new GUIEvent( GUIEvent.APP_ACTIVATE ) )
			}
			//else
			//	Log.out( "VoxelVerse.activateApp - ignoring" )
		}

		private function deactivateApp():void {
			
			//Log.out( "VoxelVerse.deactivateApp", Log.WARN )
			if ( true == Globals.active ) {
				//Log.out( "VoxelVerse.deactivateApp with active app", Log.WARN )
				Globals.active = false
				Globals.clicked = false
				VoxelVerseGUI.currentInstance.crossHairInactive()
				
				MemoryManager.update()
				MouseKeyboardHandler.reset()
				
				// one way to wake us back up is thru the mouse click
				//stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown)
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown)
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp)
				stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp)					

				if ( Globals.online ) {
					//Log.out( "VoxelVerse.deactivateApp - NOT SAVING REGION AND INVENTORY", Log.WARN )
					RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid ) )
					AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.SAVE, 0, null, null, null ) )
					InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, null, null ) )
					ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.SAVE, 0, "", null ) )
				}
				
	//			GUIEvent.dispatch( new GUIEvent( GUIEvent.APP_DEACTIVATE ) )
			}
			//else
			//	Log.out( "VoxelVerse.deactivateApp - app already deactivated", Log.WARN )
		}
		
		//private function mouseDown(e:MouseEvent):void 
		//{
			//stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown)
			
		//}
		
		private function mouseUp(e:MouseEvent):void 
		{
			//Log.out( "VoxelVerse.mouseUp event" )
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp)
			activateApp()
		}
		
		private function toggleConsole():void 
		{
			showConsole = false
			if ( Log.showing )
				Log.hide()
			else
				Log.show()
		}
		
		private var _shiftDown:Boolean
		private var _controlDown:Boolean
		private function keyDown(e:KeyboardEvent):void 
		{
			switch (e.keyCode) {
				//case Keyboard.BACKQUOTE:
				case Keyboard.SHIFT:
					_shiftDown = true
					break
				case Keyboard.CONTROL:
					_controlDown = true
					break
				case Keyboard.ENTER:
					// trying to stop the BACKQUOTE from getting to the doomsday console.
					//e.stopImmediatePropagation()
					if ( _controlDown )
						showConsole = true
					break
			}
		}
		
		private function keyUp(e:KeyboardEvent):void 
		{
			switch (e.keyCode) {
				//case Keyboard.BACKQUOTE:
				case Keyboard.SHIFT:
					_shiftDown = false
					break
				case Keyboard.CONTROL:
					_controlDown = false
					break
			}
		}
		////////////////////////////
        
        private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
        {
            if (event.error is Error)
            {
                var error:Error = event.error as Error
                Log.out( "VoxelVerse.uncaughtErrorHandler name: " + error.name + " message: " + error.message + "  stackTrace: " + error.getStackTrace(), Log.ERROR )
            }
            else if (event.error is ErrorEvent)
            {
                var errorEvent:ErrorEvent = event.error as ErrorEvent
                Log.out( "VoxelVerse.uncaughtErrorHandler name: " + error.name + " message: " + error.message + "  stackTrace: " + error.getStackTrace(), Log.ERROR )
            }
            else
            {
                Log.out( "VoxelVerse.uncaughtErrorHandler something was caught: " + event.toString(), Log.WARN )
            }
        }
	}
}

import com.voxelengine.Globals
import com.voxelengine.events.WindowSplashEvent
import com.voxelengine.pools.PoolManager
import com.voxelengine.worldmodel.animation.AnimationCache
import com.voxelengine.worldmodel.ConfigManager
import com.voxelengine.worldmodel.RegionManager
import com.voxelengine.worldmodel.SoundCache
import com.voxelengine.worldmodel.weapons.AmmoCache

// This class simply makes sure the startup happens in the right order. And listens for the splash screen to finish loading
class StartupSynchronizer 
{
	private var _complete:Boolean
	
	public function StartupSynchronizer( $startingModelToDisplay:String = null ) {
		
		WindowSplashEvent.addListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded )
		WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) )
		
		RegionManager.instance
		ConfigManager.instance
		//ConfigManager.instance.init( $startingModelToDisplay )
		new PoolManager()
		_complete = true
		startApp()
	}
	
	private function onSplashLoaded(e:WindowSplashEvent):void {
		WindowSplashEvent.removeListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded )
		startApp()
	}
	
	private function startApp():void {
		if ( _complete )
			Globals.g_app.readyToGo()
	}
}

import flash.display.Stage
import flash.display.LoaderInfo

import com.voxelengine.Log
import com.voxelengine.Globals

import com.voxelengine.GUI.VoxelVerseGUI
import com.voxelengine.GUI.WindowSplash
import com.voxelengine.worldmodel.MouseKeyboardHandler
import com.voxelengine.worldmodel.models.*
import com.voxelengine.worldmodel.inventory.InventoryManager
import com.voxelengine.persistance.Persistance

class VVInitializer 
{
	static public function initialize( $stage:Stage ):void {
		
		//Log.out("VVInitializer.initialize", Log.DEBUG )
		//var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent}")).toLowerCase()			
		
		// expect an exception to be thrown and caught here, the best way I know of to find out of we are in debug or release mode
		try {
			var result : Boolean = new Error().getStackTrace().search(/:[0-9]+]$/m) > -1
			Globals.g_debug = result
		} catch ( error:Error ) {
			Globals.g_debug = false
		}
		
		//Log.out("VVInitializer.initialize this is " + (Globals.g_debug ? "debug" : "release") + " build", Log.DEBUG )
		
		var url:String = $stage.loaderInfo.loaderURL
		//url = "file:///C:/dev/VoxelVerse/resources/bin/VoxelVerse.swf"
		var index:int = url.lastIndexOf( "VoxelVerse.swf" )
		Globals.appPath = url.substring( 0, index )
		//Log.out( "VVInitializer.initialize - set appPath to: " + Globals.appPath, Log.DEBUG )
		
		Globals.g_renderer.init( $stage )
		// adds handlers for persistance of regions
		Persistance.addEventHandlers()
		
		VoxelVerseGUI.currentInstance.init()
		WindowSplash.init()
		
		// This adds the event handlers
		// Is there a central place to do this?
		ModelMetadataCache.init()
		ModelInfoCache.init()
		SoundCache.init()		
		AmmoCache.init()
		OxelPersistanceCache.init()
		AnimationCache.init()
		// This causes the to load its caches and listeners
		InventoryManager.init()
		MouseKeyboardHandler.init()
		ModelCacheUtils.init()
	}
}