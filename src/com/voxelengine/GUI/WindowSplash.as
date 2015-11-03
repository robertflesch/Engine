/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
	import com.voxelengine.events.LoadingImageEvent;
	import flash.display.Bitmap;
	import flash.events.Event;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.worldmodel.RegionManager;
	
	public class WindowSplash extends VVCanvas
	{
		static public function init():void {
			WindowSplashEvent.addListener( WindowSplashEvent.CREATE, create );
			WindowSplashEvent.addListener( WindowSplashEvent.DESTORY, destroy );
			WindowSplashEvent.addListener( WindowSplashEvent.ANNIHILATE, annihilate );
		}
		
		static private function annihilate(e:WindowSplashEvent):void {
			if ( WindowSplash.isActive ) {
				WindowSplash._s_currentInstance.remove();
				WindowSplash._s_currentInstance = null;
				LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) );			
			}
		}
		
		static private function create(e:WindowSplashEvent):void {
			if ( null == _s_currentInstance )
				new WindowSplash();
		}
		
		static private function destroy(e:WindowSplashEvent):void {
			if ( WindowSplash.isActive && Globals.online )
			{
				WindowSplash._s_currentInstance.remove();
				WindowSplash._s_currentInstance = null;
				//LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTORY ) );			
			}
		}
		
		static private var _s_currentInstance:WindowSplash = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }
		
		private var _outline:Image;
		private var _splashImage:Bitmap;
		[Embed(source='../../../../embed/textures/splash.png')]
		private var _splashImageClass:Class;

		
		public function WindowSplash():void { 
			super( Globals.g_renderer.width, Globals.g_renderer.height );

			_splashImage = (new _splashImageClass() as Bitmap);
			_outline = new Image( _splashImage );
			
			if ( Globals.g_debug )
			{
				// this scale the window down, so we can see it, but it shows we are in debug
				_outline.scaleX = Globals.g_renderer.width/2791;
				_outline.scaleY = Globals.g_renderer.height/2592;
			}
			else
			{
				_outline.scaleX = Globals.g_renderer.width/791;
				_outline.scaleY = Globals.g_renderer.height / 592;
			}
			
			addElement( _outline );
			
			_s_currentInstance = this;
			
			if ( Globals.g_debug )
				display( Globals.g_renderer.width - 791, 0 );
			else
				display( 0, 0 );
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
			
			VoxelVerseGUI.currentInstance.hideGUI()
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.SPLASH_LOAD_COMPLETE ) );	
			
			//LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );			
		} 
		
        protected function onResize(event:Event):void {
			_outline.scaleX = Globals.g_renderer.width/791;
			_outline.scaleY = Globals.g_renderer.height/592;
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void {
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			_s_currentInstance = null;
			VoxelVerseGUI.currentInstance.showGUI();
		}

	}
}