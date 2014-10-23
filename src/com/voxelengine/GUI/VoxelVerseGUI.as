
package com.voxelengine.GUI
{
	import com.voxelengine.events.GUIEvent;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.events.FullScreenEvent;
	import flash.display.StageDisplayState;
	import org.flashapi.swing.Button;
	import org.flashapi.swing.event.UIOEvent;
	import org.flashapi.swing.Label;
	import org.flashapi.swing.Popup;
	import org.flashapi.swing.framework.FDTrace; // Allows FlashDevelop to trace
	
	import org.flashapi.swing.UIManager;
	
	import playerio.DatabaseObject;
	import playerio.PlayerIOError;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	
	import com.voxelengine.server.WindowLogin;
	import com.voxelengine.server.EventHandlers;
	import com.voxelengine.server.Network;
	
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.VoxelModel;
//	import com.voxelengine.worldmodel.scripts.FireProjectileScript;
	
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
		private var _fileReference:FileReference = new FileReference();
		private var _projectileEnabled:Boolean = true;
		private var _hub:Hub = null;

		static private var _currentInstance:VoxelVerseGUI = null;
		static public function get currentInstance():VoxelVerseGUI 
		{
			if ( null == _currentInstance )
				_currentInstance = new VoxelVerseGUI();
				
			return _currentInstance;
		}
		

		//	CONSTRUCTOR
		//	----------------------------------------------------------------
		public function VoxelVerseGUI(title : String = null) { 
			
			Globals.g_app.stage.addEventListener( FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
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
		
		public function get toolBar(): Hub { return _hub; }
		
		private function createProjectile( vm:VoxelModel ):void  {
			/*
			if ( _projectileEnabled )
			{
				var ps:FireProjectileScript = new FireProjectileScript( _bulletSize );
				ps.accuracy = 0;
				ps.velocity = 1200;
				ps.owner = Globals.player.instanceInfo.instanceGuid;
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
		
		public function saveModelIVM():void 
		{
			trace("VoxelVerseGUI.saveModel - Saving model to FILE");
			 //three steps
			 //save updated model meta data with new guid
			 //save updated model ivm
			 //update the model manager, removing old guid and adding new guid
			var vm:VoxelModel = Globals.selectedModel;
			if ( !vm )
				vm = Globals.modelInstancesGetFirst();
			if ( vm )
			{
				//if ( Network.client )
					//vm.save();
				//else
				{
					var ba:ByteArray = vm.toByteArray();

					_fileReference.save( ba, vm.modelInfo.fileName + "_new.ivm");
				}
			}
			else
				Log.out( "VoxelVerseGUI.saveModelIVM - No VoxelModel selected", Log.ERROR );
		}
		
		private function crossHairResize(event:Event):void {
			//trace( "VoxelVerseGUI.crossHairResize" );
			if ( _crossHairHorizontal )
			{
				var halfRW:int = Globals.g_renderer.width / 2;
				var halfRH:int = Globals.g_renderer.height / 2;
				_crossHairHorizontal.x = halfRW - _crossHairHorizontal.width/2;
				_crossHairHorizontal.y = halfRH;
				_crossHairVertical.x = halfRW;
				_crossHairVertical.y = halfRH - _crossHairVertical.height / 2;
				
			}
			
			if ( _hub )
				_hub.resizeHub( event );
		}
		
		public function crossHairActive():void {
			_crossHairColor = CROSS_HAIR_YELLOW;
			crossHairChange();
		}
		
		public function crossHairInactive():void {
			_crossHairColor = CROSS_HAIR_RED;
			crossHairChange();
		}
		
		/*
		private function deactivate(e:Event):void {
			//Log.out( "VoxelVerseGUI.DEactivate - change cross hairs:" + e.toString() );
			_crossHairColor = CROSS_HAIR_RED;
			crossHairChange();
			crossHairShow();
		}
		
		private function activate(e:Event):void {
			//Log.out( "VoxelVerseGUI.activate - change cross hairs:" + e.toString() );
			_crossHairColor = CROSS_HAIR_YELLOW;
			crossHairChange();
			if ( _crossHairHide )
				crossHairHide();
			else
				crossHairShow();
		}
		*/
		private function addReleaseMenu():WindowReleaseMenu
		{
			if ( Globals.g_app.configManager.showButtons && Globals.g_app.configManager.showEditMenu )
			{
				crossHairAdd();
			}
			
			return new WindowReleaseMenu();
		}
		
		//private function showHelpWindow():void
		//{
			//new WindowHelp();
		//}
		
		private function crossHairAdd():void
		{
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

		private function crossHairChange():void
		{
			if ( !_crossHairAdded )
			{
				//trace( "VoxelVerseGUI.changeCrossHairs - _crossHairAdded not yet added" );
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
		
		private function guiEventHandler( e:GUIEvent ):void
		{
			if ( GUIEvent.TOOLBAR_HIDE == e.type )
			{
				if ( _hub ) _hub.hide();
				crossHairHide();

			}
			else if ( GUIEvent.TOOLBAR_SHOW == e.type )
			{
				if ( _hub ) _hub.show();
				crossHairShow()
			}
		}
		
		
		public function hideGUI():void 
		{
			trace( "VoxelVerseGUI.hideGUI" ); 
			if ( _built )
			{
				if ( _debugMenu )
					_debugMenu.visible = false;
				if ( _releaseMenu )
					_releaseMenu.visible = false;
				if ( _hub )
					_hub.visible = false;
				crossHairHide();
			}
			
		}
		
		public function buildGUI():void 
		{
			if ( _built )
			{
				if ( _debugMenu )
					_debugMenu.visible = true;
				if ( _releaseMenu )
					_releaseMenu.visible = true;
				if ( _hub )
					_hub.visible = true;
				crossHairShow();
				return;	
			}
			
			//if ( false == Globals.g_debug )
				//new  WindowSplash();
			
			_releaseMenu = addReleaseMenu();
			//if ( true == Globals.g_debug )
				_debugMenu = new WindowDebugMenu();
			
			if ( Globals.g_app.configManager.showEditMenu )
			{
				_hub = new Hub();
			}
			
			if ( !Globals.g_renderer.hardwareAccelerated )
				 new WindowNotHardware( "WARNING", "Hardware acceleration is not enabled in your browser, this is happening in Chrome on some machines, try FireFox or Internet Explorer" );
				 
		}
		
		public function init():void
		{
            UIManager.initialize( Globals.g_app.stage );
			UIManager.debugger = new FDTrace();
			Globals.g_app.addEventListener( RegionEvent.REGION_LOAD_BEGUN, onRegionLoadingComplete );
			Globals.g_app.addEventListener( LoadingEvent.LOAD_COMPLETE, onModelLoadingComplete );
			Globals.g_app.addEventListener( GUIEvent.TOOLBAR_HIDE, guiEventHandler );
			Globals.g_app.addEventListener( GUIEvent.TOOLBAR_SHOW, guiEventHandler );
//			Globals.g_app.addEventListener(Event.DEACTIVATE, deactivate);
//			Globals.g_app.addEventListener(Event.ACTIVATE, activate);
//			Globals.g_app.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
			
			Globals.g_app.addEventListener(ModelEvent.TAKE_CONTROL, WindowBeastControl.handleModelEvents );
			Globals.g_app.addEventListener(ModelEvent.RELEASE_CONTROL, WindowBeastControl.handleModelEvents );
			Globals.g_app.addEventListener(ModelEvent.TAKE_CONTROL, WindowBeastControlQuery.handleModelEvents );
			Globals.g_app.addEventListener(LoginEvent.JOIN_ROOM_FAILURE, joinRoomFailureHandler );
		}
		
		private function joinRoomFailureHandler( e:LoginEvent ):void {
			
			var popup:VVPopup = new VVPopup("NO SERVERS FOUND");
			popup.width = 250;
			popup.height = 50;
            //popup.innerPanel = popup.autoHeight = true;
            
            var label:Label = new Label("No servers were found for this room, try later");
			popup.addElement(label);
            
			popup.display( Globals.g_renderer.width / 2 - (((popup.width + 10) / 2) + popup.x ), Globals.g_renderer.height / 2 - (((popup.height + 10) / 2) + popup.y) );
			popup.eventCollector.addEvent( popup, UIOEvent.REMOVED, function( e:UIOEvent ):void { new WindowSandboxList(); popup.remove(); } );
		}

		private function addKeyboardListeners(event : Event) : void
		{
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		}

		//private function removeKeyboardListeners(event : Event) : void
		//{
			//Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		//}

		
		private function onRegionLoadingComplete(event : RegionEvent ) : void
		{
			Globals.g_app.removeEventListener(RegionEvent.REGION_LOAD_BEGUN, onRegionLoadingComplete);
			
			if ( true == Globals.sandbox )
			{
				EventHandlers.addEventHandlers();
			}
			else
			{
				Globals.mode = Globals.MODE_PUBLIC;
				//WindowLogin.autoLogin();
			}
		}
		
		private function onModelLoadingComplete(event : LoadingEvent ) : void
		{
			//Log.out( "VVGui.onModelLoadingComplete" );
			Globals.g_app.removeEventListener( LoadingEvent.LOAD_COMPLETE, onModelLoadingComplete );
			addKeyboardListeners( event );
			new WindowLogin();
		}
		
		private function onKeyPressed( e : KeyboardEvent) : void
		{
			//if ( Keyboard.F == e.keyCode )
			//{
				//createProjectile( Globals.controlledModel );
				//return;
			//}
			if ( ( 0 < Globals.openWindowCount || Log.showing) )
				return;				
				
			//trace( "onKeyPressed: " + e.keyCode );	
//			if ( true == Globals.g_debug )
			if ( !Log.showing )
			{
				if ( Keyboard.T == e.keyCode )
					Globals.player.torchToggle();
					
				if ( Keyboard.F11 == e.keyCode )
					Globals.g_renderer.screenShot( true );

				if ( Keyboard.F12 == e.keyCode )
					Globals.g_renderer.screenShot( false );
					
				if ( Keyboard.F9 == e.keyCode )
					toggleFullscreen();
					
					
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
					createProjectile( Globals.controlledModel )
				
				if ( Keyboard.P == e.keyCode )
					new WindowSandboxList();
					
				if ( Keyboard.M == e.keyCode )
					saveModelIVM();

				if ( Keyboard.N == e.keyCode )
					new WindowModelsForRegion();
					//new WindowVideoTest(); Wait for hummingbird
			}
			
			if  ( Globals.g_app.configManager.showEditMenu )
			{
				if ( Keyboard.I == e.keyCode )
					new WindowInventory();
					
				if ( Keyboard.O == e.keyCode )
				{
					Globals.TestCheckForFlow();
					//Globals.g_renderer.context.dispose();
				}
				
				if ( Keyboard.L == e.keyCode )
				{
					Globals.muted = !Globals.muted;
				}
			}
		}
	}
}