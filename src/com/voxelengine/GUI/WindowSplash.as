/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
import com.voxelengine.renderer.Renderer;

import flash.display.Bitmap;
	import flash.events.Event;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;

	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.events.LoadingImageEvent;

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
				LoadingImageEvent.create( LoadingImageEvent.DESTROY );
			}
		}
		
		static private function create(e:WindowSplashEvent):void {
			if ( null == _s_currentInstance )
				new WindowSplash();
		}
		
		static private function destroy(e:WindowSplashEvent):void {
			if ( WindowSplash.isActive && Globals.online ) {
				WindowSplash._s_currentInstance.remove();
				WindowSplash._s_currentInstance = null;
			}
		}
		
		static private var _s_currentInstance:WindowSplash = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }
		
		private var _outline:Image;
		[Embed(source='../../../../embed/textures/splash.png')]
		private var _splashImageClass:Class;

		
		public function WindowSplash():void { 
			super( Renderer.renderer.width, Renderer.renderer.height );

			_outline = new Image( (new _splashImageClass() as Bitmap) );

			addElement( _outline );
			
			_s_currentInstance = this;
			
			if ( Globals.isDebug )
				display( Renderer.renderer.width - 791, Renderer.renderer.height - 592);
			else
				display( 0, 0 );
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
			
			VoxelVerseGUI.currentInstance.hideGUI();
			onResize(null);
			WindowSplashEvent.create( WindowSplashEvent.SPLASH_LOAD_COMPLETE );
			
			//LoadingImageEvent.create( LoadingImageEvent.CREATE ) );
		} 
		
        protected function onResize(event:Event):void {
            if ( Globals.isDebug ){
				_outline.scaleX = Renderer.renderer.width/2791; // 791 is width of splash screen
				_outline.scaleY = Renderer.renderer.height/2592; // 592 is height of splash screen
			} else {
                _outline.scaleX = Renderer.renderer.width/791; // 791 is width of splash screen
                _outline.scaleY = Renderer.renderer.height/592; // 592 is height of splash screen
			}
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void {
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			_s_currentInstance = null;
			VoxelVerseGUI.currentInstance.showGUI();
		}

	}
}