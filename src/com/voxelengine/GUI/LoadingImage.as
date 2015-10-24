/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Matrix;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoadingImageEvent;
	
	public class LoadingImage extends VVCanvas
	{
		static public function init():void {
			LoadingImageEvent.addListener( LoadingImageEvent.CREATE, create );
			LoadingImageEvent.addListener( LoadingImageEvent.DESTROY, destroy );
			LoadingImageEvent.addListener( LoadingImageEvent.ANNIHILATE, annihilate );
		}
		
		static private function annihilate(e:LoadingImageEvent):void {
			if ( LoadingImage.isActive ) {
				LoadingImage._s_currentInstance.remove();
				LoadingImage._s_currentInstance = null;
			}
		}
		
		static private function create(e:LoadingImageEvent):void {
			if ( null == _s_currentInstance )
				new LoadingImage();
		}
		
		static private function destroy(e:LoadingImageEvent):void {
//			Log.out( "LoadingImage.destroy called", Log.WARN );
			if ( LoadingImage.isActive && Globals.online )
			{
				//Log.out( "LoadingImage.DESTROYED", Log.WARN );
				LoadingImage._s_currentInstance.remove();
				LoadingImage._s_currentInstance = null;
			}
		}
		
		static private var _s_currentInstance:LoadingImage = null;
		static public function get isActive():Boolean { return _s_currentInstance ? true: false; }
		
		private const _angle:Number = 0.5236;
		private var _count:int = 0;
		private var _outline:Image;
		private var _splashImage:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/loadingCursor.png')]
		private var _splashImageClass:Class;

		
		public function LoadingImage():void { 
			//Log.out( "LoadingImage.constructor", Log.WARN );
			super( Globals.g_renderer.width, Globals.g_renderer.height );
			_s_currentInstance = this;

			_splashImage = (new _splashImageClass() as Bitmap);
			_outline = new Image( _splashImage );
			addElement( _outline );
			
			display( _outline.x, _outline.x );
			onResize( null );
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
			Globals.g_app.addEventListener( Event.ENTER_FRAME, onEnterFrame );
		} 
		
        protected function onResize(event:Event):void {
			// still kinda funky in placement.... but works.
			_outline.x = Globals.g_renderer.width / 2 - _outline.x / 2
			_outline.y = Globals.g_renderer.height / 2 - _outline.y / 2
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void {
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.stage.removeEventListener( Event.RESIZE, onResize );
			Globals.g_app.removeEventListener( Event.ENTER_FRAME, onEnterFrame );
			
			_s_currentInstance = null;
		}
		
		private function onEnterFrame( e:Event ):void {
			rotateImage( _angle );
		}
		
		private function rotateImage(degrees:Number):void {
			_count++;
			
			if ( 0 == _count % 5 ) {
				// Calculate rotation and offsets
				var radians:Number = degrees* (Math.PI / 180.0);
				var offsetWidth:Number = _outline.width/2.0;
				var offsetHeight:Number =  _outline.height/2.0;

				// Perform rotation
				var matrix:Matrix = new Matrix();
				matrix.translate(-offsetWidth, -offsetHeight);
				matrix.rotate(degrees); // radians);
				matrix.translate(+offsetWidth, +offsetHeight);
				matrix.concat(_outline.transform.matrix);
				_outline.transform.matrix = matrix;
			}
		}			
	}
}