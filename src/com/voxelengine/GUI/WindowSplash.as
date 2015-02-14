/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.RegionManager;
	import flash.display.Bitmap;
	import com.voxelengine.events.LoadingEvent;
	import flash.events.Event;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	public class WindowSplash extends VVCanvas
	{
		static private var _s_currentInstance:WindowSplash = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }
		static public function create():WindowSplash 
		{  
			if ( null == _s_currentInstance )
				new WindowSplash();
			return _s_currentInstance; 
		}
		
		private var _outline:Image;
		private var _splashImage:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/splash.png')]
		private var _splashImageClass:Class;

		
		public function WindowSplash():void 
		{ 
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
			RegionManager.addListener( RegionEvent.REGION_LOAD_COMPLETE, onLoadingComplete );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
			
			VoxelVerseGUI.currentInstance.hideGUI()
			Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.SPLASH_LOAD_COMPLETE ) );			
		} 
		
        protected function onResize(event:Event):void
        {
			_outline.scaleX = Globals.g_renderer.width/791;
			_outline.scaleY = Globals.g_renderer.height/592;
		}
		
		private function onLoadingComplete( le:RegionEvent ):void
		{
			Globals.g_app.removeEventListener( RegionEvent.REGION_LOAD_COMPLETE, onLoadingComplete );
			if ( WindowSplash.isActive && Globals.online )
			{
				WindowSplash._s_currentInstance.remove();
				WindowSplash._s_currentInstance = null;
			}
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			_s_currentInstance = null;
			VoxelVerseGUI.currentInstance.showGUI();
		}

	}
}