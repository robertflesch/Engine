/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.net.FileReference;
import flash.ui.Keyboard;
import flash.events.FullScreenEvent;
import flash.display.StageDisplayState;

import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.Label;
import org.flashapi.swing.framework.FDTrace; // Allows FlashDevelop to trace FlashAPI messages
import org.flashapi.swing.UIManager;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RoomEvent;

import com.voxelengine.GUI.actionBars.UserInventory;
import com.voxelengine.GUI.crafting.WindowCrafting;
import com.voxelengine.GUI.inventory.WindowInventory;
import com.voxelengine.GUI.inventory.WindowInventoryNew;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.GUI.voxelModels.WindowRegionModels;

import com.voxelengine.renderer.Renderer;

import com.voxelengine.server.WindowLogin;
import com.voxelengine.server.RoomConnection;

import com.voxelengine.worldmodel.ConfigManager;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class VoxelVerseGUI extends EventDispatcher
{
	//	----------------------------------------------------------------
	//	PRIVATE MEMBERS
	//	----------------------------------------------------------------
	
	private const CROSS_HAIR_YELLOW:int = 0xCCFF00;
	private const CROSS_HAIR_RED:int = 0xFF0000;
	private var _crossHairColor:int = CROSS_HAIR_RED;
	private var _crossHairHorizontal : Sprite = new Sprite();
	private var _crossHairVertical : Sprite = new Sprite();
	private var _crossHairAdded:Boolean = false;
	private var _crossHairHide:Boolean = false;
	
	private var _built:Boolean = false;
	private var _debugMenu:WindowDebugMenu = null;
	private var _releaseMenu:WindowReleaseMenu = null;
	public function releaseMenu():WindowReleaseMenu { return _releaseMenu; }

	private var _fileReference:FileReference = new FileReference();
	private var _projectileEnabled:Boolean = true;
	
	static private var _currentInstance:VoxelVerseGUI = null;
	static public function get currentInstance():VoxelVerseGUI { return ( _currentInstance ? _currentInstance : _currentInstance = new VoxelVerseGUI() ); }
	
	//	CONSTRUCTOR
	//	----------------------------------------------------------------
	public function VoxelVerseGUI(title : String = null) { 
		Globals.g_app.stage.addEventListener( FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
		LoadingImage.init();
		UserInventory.init();
	}
	
	private function fullScreenEvent(event:FullScreenEvent):void {
		if ( event.fullScreen )
		{
			//Log.out( "Renderer - enter fullscreen has been called" + event );
			if( !Globals.g_app.stage.mouseLock )
				Globals.g_app.stage.mouseLock = true;
		}
		else if ( !event.fullScreen )
		{
			//Log.out( "Renderer - leaving fullscreen has been called" + event );
		}
	}
	
	public function toggleFullscreen():void {
		if ( StageDisplayState.NORMAL == Globals.g_app.stage.displayState )
			Globals.g_app.stage.displayState =	StageDisplayState.FULL_SCREEN_INTERACTIVE;
		else
			Globals.g_app.stage.displayState =	StageDisplayState.NORMAL;
	}
	
	private function createProjectile( vm:VoxelModel ):void  {
		/*
		if ( _projectileEnabled )
		{
			var ps:FireProjectileScript = new FireProjectileScript( _bulletSize );
			ps.accuracy = 0;
			ps.velocity = 1200;
			ps.owner = Player.player.instanceInfo.instanceGuid;
			ps.onModelEvent( new ModelEvent( WeaponEvent.FIRE, "" ) );
			
			_projectileEnabled = false;
			var pt:Timer = new Timer( 1000, 1 );
			pt.addEventListener(TimerEvent.TIMER, onEnableProjectile );
			pt.start();
		}
		*/
	}

	protected function onEnableProjectile(event:TimerEvent):void {
		_projectileEnabled = true;
	}
	
	//public function saveModelIVM():void {
		//Log.out("VoxelVerseGUI.saveModel - Saving model to FILE");
		 ////three steps
		 ////save updated model meta data with new guid
		 ////save updated model ivm
		 ////update the model manager, removing old guid and adding new guid
		//var vm:VoxelModel = VoxelModel.selectedModel;
		//if ( !vm )
			//vm = Globals.modelInstancesGetFirst();
		//if ( vm )
		//{
			//var ba:ByteArray = vm.toByteArray();
			//_fileReference.save( ba, vm.modelInfo.fileName + "_new.ivm");
		//}
		//else
			//Log.out( "VoxelVerseGUI.saveModelIVM - No VoxelModel selected", Log.ERROR );
	//}
	
	private function crossHairResize(event:Event):void {
		//Log.out( "VoxelVerseGUI.crossHairResize" );
		if ( _crossHairHorizontal )
		{
			var halfRW:int = Renderer.renderer.width / 2;
			var halfRH:int = Renderer.renderer.height / 2;
			_crossHairHorizontal.x = halfRW - _crossHairHorizontal.width/2;
			_crossHairHorizontal.y = halfRH;
			_crossHairVertical.x = halfRW;
			_crossHairVertical.y = halfRH - _crossHairVertical.height / 2;
			
		}
	}
	
	public function crossHairActive():void {
		//Log.out( "VoxelVerseGUI.crossHairActive event Globals.active: " + Globals.active, Log.WARN );

		_crossHairColor = CROSS_HAIR_YELLOW;
		crossHairChange();
	}
	
	public function crossHairInactive():void {
		//Log.out( "VoxelVerseGUI.crossHairInactive event Globals.active: " + Globals.active, Log.WARN );

		_crossHairColor = CROSS_HAIR_RED;
		crossHairChange();
	}
	
	private function addReleaseMenu():WindowReleaseMenu {
		if ( ConfigManager.instance.showButtons && ConfigManager.instance.showEditMenu )
		{
			crossHairAdd();
		}
		
		return new WindowReleaseMenu();
	}
	
	private function crossHairAdd():void {
		_crossHairHorizontal.graphics.beginFill(_crossHairColor);
		_crossHairHorizontal.graphics.drawRect(0, 0, 50, 1);
		Globals.g_app.addChild(_crossHairHorizontal);
		
		_crossHairVertical.graphics.beginFill(_crossHairColor);
		_crossHairVertical.graphics.drawRect(0, 0, 1, 50);
		Globals.g_app.addChild(_crossHairVertical);
		
		Globals.g_app.stage.addEventListener( Event.RESIZE, crossHairResize );

		_crossHairAdded = true;
		crossHairResize( null );
	}

	private function crossHairChange():void {
		if ( !_crossHairAdded )
		{
			//Log.out( "VoxelVerseGUI.changeCrossHairs - _crossHairAdded not yet added" );
			return;
		}
			
		Globals.g_app.removeChild(_crossHairHorizontal);
		Globals.g_app.removeChild(_crossHairVertical);
		_crossHairHorizontal = new Sprite();
		_crossHairVertical = new Sprite();
		
		crossHairAdd();
	}
	
	public function crossHairShow():void {
		if ( _crossHairHorizontal )
			_crossHairHorizontal.visible = true;
		if ( _crossHairVertical )
			_crossHairVertical.visible = true;
	}
	
	public function crossHairHide():void {
		if ( _crossHairHorizontal )
			_crossHairHorizontal.visible = false;
		if ( _crossHairVertical )
			_crossHairVertical.visible = false;
			
		_crossHairHide = true;	
	}
	
	public function hideGUI():void {
		//Log.out( "VoxelVerseGUI.hideGUI" ); 
		if ( _built )
		{
			if ( _debugMenu )
				_debugMenu.visible = false;
			if ( _releaseMenu )
				_releaseMenu.visible = false;
			crossHairHide();
		}
	}
	
	public function showGUI():void {
		//Log.out( "VoxelVerseGUI.showGUI" ); 
		if ( _built )
		{
			if ( _debugMenu )
				_debugMenu.visible = true;
			if ( _releaseMenu )
				_releaseMenu.visible = true;
			crossHairShow();
		}
	}
	
	
	public function buildGUI():void {
		Log.out( "VoxelVerseGUI.buildGUI", Log.DEBUG ); 
		if ( !_built ) {
			_releaseMenu = addReleaseMenu();
			_releaseMenu.visible = false;
//			if ( true == Globals.isDebug ) {
//				_debugMenu = new WindowDebugMenu();
//				_debugMenu.visible = false;
//			}
			if ( !Renderer.renderer.hardwareAccelerated )
				 new WindowNotHardware( "WARNING", "Hardware acceleration is not enabled in your browser, this is happening in Chrome on some machines, try FireFox or Internet Explorer" );
			_built = true;
		}
	}

	public function init():void {
		UIManager.initialize( Globals.g_app.stage );
		UIManager.debugger = new FDTrace();
		RegionEvent.addListener( RegionEvent.LOAD_BEGUN, onRegionLoadingComplete );
		ModelEvent.addListener( ModelEvent.TAKE_CONTROL, WindowBeastControlQuery.handleModelEvents );
		LoginEvent.addListener(LoginEvent.LOGIN_SUCCESS, WindowSandboxList.listenForLoginSuccess );
		RoomEvent.addListener(RoomEvent.ROOM_JOIN_FAILURE, joinRoomFailureHandler );
		
		LanguageManager.init();
	}
	
	private function addKeyboardListeners() : void {
		Log.out( "VoxelVerseGUI.addKeyboardListeners");
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
	}

	//private function removeKeyboardListeners(event : Event) : void
	//{
		//Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
	//}

	
	private function onRegionLoadingComplete(event : RegionEvent ) : void {
		RegionEvent.removeListener(RegionEvent.LOAD_BEGUN, onRegionLoadingComplete);
		
		if ( false == Globals.inRoom ) {
			RoomConnection.addEventHandlers();
		} else {
			Globals.mode = Globals.MODE_PUBLIC;
			//WindowLogin.autoLogin();
		}

		if ( ConfigManager.instance.showHelp )
			new WindowHelp();
		else
			new WindowLogin( "", "" );

		addKeyboardListeners();
	}
	
	private function onKeyPressed( e : KeyboardEvent) : void {
		//Log.out( "VoxelVerseGUI.onKeyPressed: KeyboardEvent: " + e.keyCode );
		if ( Keyboard.F11 == e.keyCode )
			Renderer.renderer.screenShot( true ); // draws UI

		if ( Keyboard.F12 == e.keyCode )
			Renderer.renderer.screenShot( false );
			
		if ( Log.showing )
			return;
			
		if ( Keyboard.F9 == e.keyCode )
			toggleFullscreen();
				
		if  ( ConfigManager.instance.showEditMenu  )
		{
			if ( Keyboard.I == e.keyCode && false == Globals.g_textInput ) {
				//var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_OWNED, WindowInventoryNew.INVENTORY_CAT_MODELS );
				var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_LAST, WindowInventoryNew.INVENTORY_CAT_LAST );
				WindowInventoryNew.toggle( startingTab )
			}

			if ( Keyboard.N == e.keyCode && false == Globals.g_textInput )
				WindowRegionModels.toggle()
				//new WindowVideoTest(); Wait for hummingbird

			//if ( Keyboard.O == e.keyCode )
			//{
				//Globals.TestCheckForFlow();
				////Renderer.renderer.context3D.dispose();
			//}
			
			if ( Keyboard.L == e.keyCode )
			{
				Globals.muted = !Globals.muted;
			}
		}
		// this is required for windows that have text fields. 
		// but if I have crafting up, then I need to have inventory up too.
		// TODO Fix this, question is how, do I bring both the crafting AND inventory window up,
		// or do I give the crafting window access to the inventory thru some built in mechanism
		if ( ( 0 < Globals.openWindowCount ) )
			return;				
			
		if ( false == Globals.g_textInput ) {
			if ( Keyboard.T == e.keyCode )
				if ( Player.player )
					VoxelModel.controlledModel.torchToggle();
				
			if ( Keyboard.F == e.keyCode )
				createProjectile( VoxelModel.controlledModel );
				
			//if ( Keyboard.O == e.keyCode )
			//{
				//_bulletSize++;
				//if ( _bulletSize > 5 )
					//_bulletSize = 5;
				//Log.out( "VVGui.onKeyPressed - increased bullet size to: " + _bulletSize );
			//}
			//if ( Keyboard.P == e.keyCode )
			//{
				//_bulletSize--;
				//if ( _bulletSize < 1 )
					//_bulletSize = 1;
				//Log.out( "VVGui.onKeyPressed - decreased bullet size to: " + _bulletSize );
			//}
				
			if ( Keyboard.F == e.keyCode )
				createProjectile( VoxelModel.controlledModel )
			
			if ( Keyboard.P == e.keyCode )
				new WindowSandboxList();
				
			if ( Keyboard.M == e.keyCode )
				if ( VoxelModel.selectedModel )
					new WindowModelDetail( VoxelModel.selectedModel );
				
			if ( Keyboard.C == e.keyCode ) {
				new WindowCrafting();
				new WindowInventory();
			}
/*
			// allows for saving of ivm to disk
			if ( Globals.isDebug ) {
				if (Keyboard.O == e.keyCode) {
					// save current oxelData
					const _fileRef:FileReference = new FileReference();
					if (VoxelModel.selectedModel) {
						var ba:ByteArray = OxelPersistence.toByteArray(VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel);
						var fileName:String = VoxelModel.selectedModel.metadata.name + "_NEW" + ".ivm";
						_fileRef.save(ba, fileName);
					}
				}
			}
 */
		}
	}
	
	private function joinRoomFailureHandler( e:RoomEvent ):void {
		
		var popup:VVPopup = new VVPopup("NO SERVERS FOUND");
		popup.width = 250;
		popup.height = 50;
		//popup.innerPanel = popup.autoHeight = true;
		
		var label:Label = new Label("No servers were found for this room, try later");
		popup.addElement(label);
		
		popup.display( Renderer.renderer.width / 2 - (((popup.width + 10) / 2) + popup.x ), Renderer.renderer.height / 2 - (((popup.height + 10) / 2) + popup.y) );
		popup.eventCollector.addEvent( popup, UIOEvent.REMOVED, function( e:UIOEvent ):void { new WindowSandboxList(); popup.remove(); } );
	}
	
}
}