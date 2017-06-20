/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
import com.voxelengine.GUI.WindowSplash;
import com.voxelengine.GUI.WindowWater;
import com.voxelengine.events.AnimationEvent
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.persistance.Persistence;
import com.voxelengine.pools.PoolManager;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.worldmodel.ConfigManager;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.ModelInfoCache;
import com.voxelengine.worldmodel.models.ModelMetadataCache;
import com.voxelengine.worldmodel.models.OxelPersistenceCache;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.lighting.LightAdd;
import com.voxelengine.worldmodel.tasks.lighting.LightRemove;
import com.voxelengine.worldmodel.weapons.AmmoCache;

import flash.display.Sprite
import flash.display.StageAlign
import flash.display.StageScaleMode
import flash.events.Event
import flash.events.KeyboardEvent
import flash.events.MouseEvent
import flash.events.ErrorEvent
import flash.events.UncaughtErrorEvent
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

[SWF(frameRate="90",width="960",height="540",backgroundColor="0xffffff")]
public class VoxelVerse extends Sprite
{
	// Main C'tor for project
	public function VoxelVerse():void {
		addEventListener(Event.ADDED_TO_STAGE, init);
		Globals.g_app = this;
		//_s_appStartTime = getTimer();
	}

	private function init(e:Event = null):void {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		initializeDataBeforeSplash();

		WindowSplashEvent.addListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
		WindowSplashEvent.create( WindowSplashEvent.CREATE );
	}

	private var _splashDisplayed:Boolean;
	private function onSplashLoaded(e:WindowSplashEvent):void {
		//Log.out( "SPLASH_DISPLAYED" );
		WindowSplashEvent.removeListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
		_splashDisplayed = true;
		addEventListener(Event.ENTER_FRAME, enterFrame);
	}

	private function initializeDataBeforeSplash():void {
		Log.init();
		//Log.out("VoxelVerse.initializeDataBeforeSplash this is " + (Globals.isDebug ? "debug" : "release") + " build", Log.WARN );

		var url:String = stage.loaderInfo.loaderURL;
		var index:int = url.lastIndexOf( "VoxelVerse.swf" );
		// Release, debug false
		if ( -1 != index ) {
			Globals.setDebug = false;
			Globals.appPath = url.substring(0, index);
		}
		else {
			// Not release, so check for old debug
			index = url.lastIndexOf("VoxelVerseD.swf");
			if (-1 != index) {
				Globals.setDebug = true;
		    } else {
				// check for new debug
				index = url.lastIndexOf("VoxelVerseDDesk.swf");
				if (-1 != index)
					Globals.setDebug = true;
				else
					Log.out("VoxelVerse.initializeDataBeforeSplash - App path not being set correctly appPath: " + url, Log.ERROR);
			}
			Globals.appPath = url.substring(0, index);
		}

		Log.out( "VVInitializer.initialize - set appPath to: " + Globals.appPath);

		Renderer.renderer.init( stage );
		VoxelVerseGUI.currentInstance.init();
		WindowSplash.init();
	}

	static private function initializeDataAfterSplash():void {

		WindowWater.init();

		Persistence.addEventHandlers();
		ModelMetadataCache.init();
		ModelInfoCache.init();
		SoundCache.init();
		AmmoCache.init();
		OxelPersistenceCache.init();
		AnimationCache.init();
		ModelCacheUtils.init();

		InventoryManager.init();
		MouseKeyboardHandler.init();
		RegionManager.instance;
		ConfigManager.instance;
		LightAdd.init();
		LightRemove.init();
		//ConfigManager.instance.init( $startingModelToDisplay )

		// All the init time is trivial compared to this.
		new PoolManager();

	}

	// after the splash and config have been loaded
	public function readyToGo():void	{
		Log.out( "<===============VoxelVerse.readyToGo - ENTER", Log.DEBUG );

		_s_timeEntered = getTimer();

		initializeDataAfterSplash();

		// These two should be the same
		// https://gamesnet.yahoo.net/forum/viewtopic.php?f=33&t=35896&sid=1f0b0c5bef7f97c6961760b6a3418c69
		// for reference
		//Security.loadPolicyFile( "http://cdn.playerio.com/crossdomain.xml" )
		//Security.loadPolicyFile( "https://content.playerio.com/crossdomain.xml" );

		VoxelVerseGUI.currentInstance.buildGUI();

		stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		mouseUp( null );
		Log.out("<===============VoxelVerse.readyToGo: " + (getTimer() - _s_timeEntered) );
	}

	private var _fpsStat:int;
	public function get fps():int 					{ return _fpsStat; }

	private var _s_timeEntered:int;
	private var _s_timeExited:int = getTimer();

	//private var _s_appStartTime:int;
	private var _s_timeLastFPS:int;
	private var _s_frameCounter:int = 0;
	private var framesToDisplaySplash:int;

	private function enterFrame(e:Event):void {
		if ( 0 == _s_timeEntered ) {
			// Give the app one frame to display splash screen before doing anything
			if ( _splashDisplayed && ( 1 == framesToDisplaySplash) )
				readyToGo();
			else{
				framesToDisplaySplash++;
				return;
			}
		}
		// Do this after checking it for 0
		_s_timeEntered = getTimer();
		_s_frameCounter++;

		var interFrameTime:int = _s_timeEntered - _s_timeExited;
		//Log.out( "VoxelVerse.enterFrame -  interFrameTime: " + interFrameTime, Log.INFO );

		MemoryManager.update();

		ModelCacheUtils.worldSpaceStartAndEndPointCalculate();

		Globals.taskController.next();

		RegionManager.instance.update( interFrameTime );
		Shader.animationOffsetsUpdate( interFrameTime );
		//var _timeUpdate:int = getTimer() - _s_timeEntered;

		Renderer.renderer.render();
		//var _timeRender:int = getTimer() - _s_timeEntered - _timeUpdate;

		if( _s_timeEntered - 1000 > _s_timeLastFPS ) {
			_s_timeLastFPS = getTimer();
			_fpsStat = _s_frameCounter;
			_s_frameCounter = 0;
//			Log.out( "VoxelVerse.enterFrame 60 frames fps: " + VoxelVerseGUI.currentInstance.releaseMenu().fps() );
		}

//		if ( ( 20 < _s_timeRender || 10 < _s_timeUpdate ) && Globals.active && Globals.isDebug )
//			Log.out( "VoxelVerse.enterFrame - update: "  + _timeUpdate + " render: " + _timeRender  + "  total: " +  (getTimer()-_s_timeEntered) + "  interFrameTime: " + interFrameTime, Log.INFO )
// Log.out( "VoxelVerse.enterFrame - update: "  + _timeUpdate + " render: " + _timeRender  + "  total: " +  (getTimer()-_s_timeEntered + " running for: " + ((getTimer()-_s_appStartTime)/1000) + " seconds"), Log.INFO )

		// For some reason is was important to make sure everything was updated before this got passed on to child classes.
		AppEvent.create( e.type );

		_s_timeExited = getTimer();
	}

	/**
	 *  Called when the mouse leaves the app by leaving the app, the active is set to false
	 *  and the mouse view is turned off.
	 *  This allow the app to not pick up any other mouse or keyboard activity when app is not active
	 */
	public function mouseLeave( e:Event ):void {
		VoxelVerseGUI.currentInstance.crossHairInactive();
		MemoryManager.update();
		MouseKeyboardHandler.reset();
		dispatchSaves();
	}

	// I only receive this if the mouse is over the app.
	private function mouseUp(e:MouseEvent):void {
//		if ( e )
//			Log.out( "VoxelVerse.mouseUp event: localX: " + e.localX + "  localY: " + e.localY + "  stageX: " + e.stageX + "  stageY: " + e.stageY);
//		else
//			Log.out( "VoxelVerse.mouseUp event" );

		VoxelVerseGUI.currentInstance.crossHairActive();
	}

	private static function dispatchSaves():void {
		//Log.out( "VoxelVerse.dispatchSaves", Log.WARN )
		if ( Region.currentRegion )
			RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid );
		AnimationEvent.create( ModelBaseEvent.SAVE, 0, null, null, null );
		var vm:VoxelModel = VoxelModel.controlledModel;
		if ( null != vm && vm.instanceInfo ) {
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, vm.instanceInfo.instanceGuid , null ) );
		}
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.SAVE, 0, "", null ) );
		OxelDataEvent.create( ModelBaseEvent.SAVE, 0, "", null );
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