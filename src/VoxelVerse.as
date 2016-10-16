/*==============================================================================
Copyright 2011-2016 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
import com.voxelengine.events.AnimationEvent
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.pools.PoolManager;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.worldmodel.ConfigManager;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.display.Sprite
import flash.display.StageAlign
import flash.display.StageScaleMode
import flash.events.Event
import flash.events.KeyboardEvent
import flash.events.MouseEvent
import flash.events.ErrorEvent
import flash.events.UncaughtErrorEvent
import flash.system.Security
import flash.ui.Keyboard
import flash.utils.getTimer

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.InventoryEvent
import com.voxelengine.events.RegionEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent
import com.voxelengine.GUI.VoxelVerseGUI
import com.voxelengine.worldmodel.RegionManager
import com.voxelengine.worldmodel.MemoryManager
import com.voxelengine.worldmodel.MouseKeyboardHandler
import com.voxelengine.worldmodel.Region

[SWF(width='512',height='512',frameRate='90',backgroundColor='0xDDDDDD')]
public class VoxelVerse extends Sprite
{
	private var _timePrevious:int = getTimer();

	private var _showConsole:Boolean;
	public function get showConsole():Boolean { return _showConsole }
	public function set showConsole(value:Boolean):void { _showConsole = value }

	// Main C'tor for project
	public function VoxelVerse():void {
		addEventListener(Event.ADDED_TO_STAGE, init);
		Globals.g_app = this;
	}

	private function init(e:Event = null):void {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		VVInitializer.initialize( stage );

		//var parameters:Object = stage.loaderInfo.parameters
		//if ( parameters.guid ) {
			//Log.out( "VVInitializer.initialize - single model found: " + parameters.guid, Log.DEBUG )
			//new LoadSynchronizer( parameters.guid )
		//}
		//else
		WindowSplashEvent.addListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
		WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) );
		//ConfigManager.instance.init( $startingModelToDisplay )
	}

	private var _splashDisplayed:Boolean;
	private function onSplashLoaded(e:WindowSplashEvent):void {
		WindowSplashEvent.removeListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
		_splashDisplayed = true;
		addEventListener(Event.ENTER_FRAME, enterFrame);
	}

	// after the splash and config have been loaded
	public function readyToGo():void	{
		Log.out( "<===============VoxelVerse.readyToGo - ENTER", Log.DEBUG )

		timeEntered = getTimer();
		RegionManager.instance;
		ConfigManager.instance;
		new PoolManager();

		// These two should be the same
		// https://gamesnet.yahoo.net/forum/viewtopic.php?f=33&t=35896&sid=1f0b0c5bef7f97c6961760b6a3418c69
		// for reference
		//Security.loadPolicyFile( "http://cdn.playerio.com/crossdomain.xml" )
		//Security.loadPolicyFile( "https://content.playerio.com/crossdomain.xml" );

		VoxelVerseGUI.currentInstance.buildGUI()

		addEventListener(Event.DEACTIVATE, deactivate);
		addEventListener(Event.ACTIVATE, activate);
		stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);

		Log.out("<===============VoxelVerse.readyToGo: " + (getTimer() - timeEntered) );
		return;

	}

//		private function mouseDown(e:MouseEvent):void {
		//Log.out( "VoxelVerse.mouseDown", Log.WARN )
//			if ( Globals.openWindowCount || !Globals.clicked || e.ctrlKey || !Globals.active )
//				return
//		}


	public static var timeEntered:int = 0;
	private function enterFrame(e:Event):void {

		//Log.out( "VoxelVerse.enterFrame" );
		if ( 0 == timeEntered )
			readyToGo();
		else
			timeEntered = getTimer();

		var elapsed:int = timeEntered - _timePrevious;
		_timePrevious = timeEntered;

		MemoryManager.update();

		RegionManager.instance.update( elapsed );
		var timeUpdate:int = getTimer() - timeEntered;
		Shader.animationOffsetsUpdate( elapsed );

		Globals.g_renderer.render();
		var timeRender:int = getTimer() - timeEntered - timeUpdate;

		if ( showConsole )
			toggleConsole();

		if ( ( 20 < timeRender || 10 < timeUpdate ) && Globals.active && Globals.g_debug )
			Log.out( "VoxelVerse.enterFrame - render: " + timeRender + "  timeUpdate: " + timeUpdate + "  total time: " +  + ( getTimer() - timeEntered ) + "  time to get back to app: " + elapsed, Log.INFO )

		// For some reason is was important to make sure everything was updated before this got passed on to child classes.
		AppEvent.dispatch( e )
	}

	private function deactivate(e:Event):void
	{
		//Log.out( "VoxelVerse.deactive event", Log.WARN )
		if ( Globals.active )
			deactivateApp(e)
	}

	private function activate(e:Event):void
	{
		//Log.out( "VoxelVerse.activate event", Log.WARN )
		activateApp(e)
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
	public static function mouseLeave( e:Event ):void {
		Log.out( "VoxelVerse.mouseLeave event" );
		dispatchSaves();
//			if ( Globals.active )
//				deactivateApp( e )
	}

	private function activateApp(e:Event):void {

		if ( false == Globals.active ) {
			//Log.out( "VoxelVerse.activateApp - setting active = TRUE" )
			Globals.active = true;
			Globals.clicked = true;
			VoxelVerseGUI.currentInstance.crossHairActive();

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

			AppEvent.dispatch( e );
		}
		//else
		//	Log.out( "VoxelVerse.activateApp - ignoring" )
	}

	private function deactivateApp(e:Event):void {

		//Log.out( "VoxelVerse.deactivateApp", Log.WARN )
		if ( true == Globals.active ) {
			//Log.out( "VoxelVerse.deactivateApp with active app", Log.WARN )
			Globals.active = false;
			Globals.clicked = false;
			VoxelVerseGUI.currentInstance.crossHairInactive();

			MemoryManager.update();
			MouseKeyboardHandler.reset();

			// one way to wake us back up is thru the mouse click
			//stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown)
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp)				;

			if ( Globals.online ) {
				AppEvent.dispatch( e );
				dispatchSaves();
			}
		}
		//else
		//	Log.out( "VoxelVerse.deactivateApp - app already deactivated", Log.WARN )
	}

	private static function dispatchSaves():void {
		//Log.out( "VoxelVerse.dispatchSaves", Log.WARN )
		if ( Region.currentRegion )
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid ) );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.SAVE, 0, null, null, null ) );
		var vm:VoxelModel = VoxelModel.controlledModel;
		if ( null != vm && vm.instanceInfo ) {
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, vm.instanceInfo.instanceGuid , null ) );
		}
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.SAVE, 0, "", null ) );
	}

	//private function mouseDown(e:MouseEvent):void
	//{
		//stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown)

	//}

	private function mouseUp(e:MouseEvent):void {
		//Log.out( "VoxelVerse.mouseUp event" )
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
//			activateApp(e)
	}

	private function toggleConsole():void {
		showConsole = false;
		if ( Log.showing )
			Log.hide();
		else
			Log.show();
	}

	private function keyDown(e:KeyboardEvent):void {
		switch (e.keyCode) {
			case Keyboard.ENTER:
				// trying to stop the BACKQUOTE from getting to the doomsday console.
				//e.stopImmediatePropagation()
				if ( MouseKeyboardHandler.ctrl )
					showConsole = true;
				break;
		}
	}

	private static function uncaughtErrorHandler(event:UncaughtErrorEvent):void {
		if (event.error is Error)
		{
			var error:Error = event.error as Error;
			Log.out( "VoxelVerse.uncaughtErrorHandler name: " + error.name + " message: " + error.message + "  stackTrace: " + error.getStackTrace(), Log.ERROR )
		}
		else if (event.error is ErrorEvent)
		{
			var errorEvent:ErrorEvent = event.error as ErrorEvent;
			Log.out( "VoxelVerse.uncaughtErrorHandler name: " + errorEvent.toString(), Log.ERROR );
		}
		else
		{
			Log.out( "VoxelVerse.uncaughtErrorHandler something was caught: " + event.toString(), Log.WARN );
		}
	}
}
}



import flash.display.Stage
import com.voxelengine.Log
import com.voxelengine.Globals

import com.voxelengine.GUI.VoxelVerseGUI
import com.voxelengine.GUI.WindowSplash
import com.voxelengine.GUI.WindowWater
import com.voxelengine.persistance.Persistance
import com.voxelengine.worldmodel.MouseKeyboardHandler
import com.voxelengine.worldmodel.models.*
import com.voxelengine.worldmodel.inventory.InventoryManager
import com.voxelengine.worldmodel.animation.AnimationCache
import com.voxelengine.worldmodel.SoundCache
import com.voxelengine.worldmodel.weapons.AmmoCache

import flash.system.Capabilities;

class VVInitializer 
{
static public function initialize( $stage:Stage ):void {

	Log.init();
	//Log.out("VVInitializer.initialize", Log.DEBUG )
	//var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent}")).toLowerCase()

	Globals.g_debug = Capabilities.isDebugger;

	Log.out("VVInitializer.initialize this is " + (Globals.g_debug ? "debug" : "release") + " build", Log.WARN );

	var url:String = $stage.loaderInfo.loaderURL;
	//url = "file:///C:/dev/VoxelVerse/resources/bin/VoxelVerse.swf"
	var index:int;
	if ( Globals.g_debug )
		index = url.lastIndexOf( "VoxelVerseD.swf" );
	else
		index = url.lastIndexOf( "VoxelVerse.swf" );
	Globals.appPath = url.substring( 0, index );
	//Log.out( "VVInitializer.initialize - set appPath to: " + Globals.appPath, Log.DEBUG )

	Globals.g_renderer.init( $stage );
	// adds handlers for persistence of regions
	Persistance.addEventHandlers();

	VoxelVerseGUI.currentInstance.init();
	WindowSplash.init();
	WindowWater.init();

	// This adds the event handlers
	// Is there a central place to do this?
	ModelMetadataCache.init();
	ModelInfoCache.init();
	SoundCache.init();
	AmmoCache.init();
	OxelPersistanceCache.init();
	AnimationCache.init();
	// This causes the to load its caches and listeners
	InventoryManager.init();
	MouseKeyboardHandler.init();
	ModelCacheUtils.init();
}
}