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
import com.voxelengine.renderer.Renderer;

import flash.display.Bitmap;
	import flash.events.Event;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.WindowWaterEvent;
	import com.voxelengine.worldmodel.RegionManager;
	
	public class WindowWater extends VVCanvas
	{
		static public function init():void {
			WindowWaterEvent.addListener( WindowWaterEvent.CREATE, create );
			WindowWaterEvent.addListener( WindowWaterEvent.DESTORY, destroy );
			WindowWaterEvent.addListener( WindowWaterEvent.ANNIHILATE, annihilate );
		}
		
		static private function annihilate(e:WindowWaterEvent):void {
			if ( WindowWater.isActive ) {
				WindowWater._s_currentInstance.remove();
				WindowWater._s_currentInstance = null;
				LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) );			
			}
		}
		
		static private function create(e:WindowWaterEvent):void {
			if ( null == _s_currentInstance )
				new WindowWater();
		}
		
		static private function destroy(e:WindowWaterEvent):void {
			if ( WindowWater.isActive && Globals.online )
			{
				WindowWater._s_currentInstance.remove();
				WindowWater._s_currentInstance = null;
				//LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTORY ) );			
			}
		}
		
		static private var _s_currentInstance:WindowWater = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }
		
		private var _outline:Image;
		private var _splashImage:Bitmap;
		[Embed(source='../../../../embed/textures/water.png')]
		private var _splashImageClass:Class;

		
		public function WindowWater():void { 
			super( Renderer.renderer.width, Renderer.renderer.height );

			_splashImage = (new _splashImageClass() as Bitmap);
			_outline = new Image( _splashImage );
			
			_outline.scaleX = Renderer.renderer.width/16;
			_outline.scaleY = Renderer.renderer.height /16;
			
			addElement( _outline );
			
			_s_currentInstance = this;
			
			display( 0, 0 );
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
		} 
		
        protected function onResize(event:Event):void {
			_outline.scaleX = Renderer.renderer.width/16;
			_outline.scaleY = Renderer.renderer.height/16;
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void {
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			_s_currentInstance = null;
		}

	}
}