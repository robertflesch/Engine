/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel 
{
	import com.voxelengine.events.RegionEvent;
	import flash.events.KeyboardEvent;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	/* 
	 * All keyboard and mouse management should go thru here
	 */
	public class MouseKeyboardHandler
	{
		static private var _s_active:Boolean  							= false;
		
		static private var _s_forward:Boolean  							= false;
		static private var _s_backward:Boolean 		 					= false;
		static private var _s_left:Boolean  							= false;
		static private var _s_right:Boolean  							= false;
		static private var _s_up:Boolean 								= false;
		static private var _s_down:Boolean 								= false;
		
		static private var _s_ctrl:Boolean 								= false;
		static private var _s_shift:Boolean 							= false;
		static private var _s_alt:Boolean 								= false;
		
		// Enable / Disable Keys
		static private var _s_leftTurnEnabled:Boolean 					= true;
		static private var _s_rightTurnEnabled:Boolean 					= true;
		
		static private var _s_handlersAdded:Boolean 					= false;
		
		static private var _s_x:Number = 0;
		static private var _s_y:Number = 0;

		static public function get leftTurnEnabled():Boolean 				{ return _s_leftTurnEnabled; }
		static public function set leftTurnEnabled(value:Boolean):void 		{ _s_leftTurnEnabled = value; }
		static public function get rightTurnEnabled():Boolean 				{ return _s_rightTurnEnabled; }
		static public function set rightTurnEnabled(value:Boolean):void 	{ _s_rightTurnEnabled = value; }
		
		static private function allowMovement( $val:Boolean ):Boolean {
			return (( Log.showing ) || (Globals.openWindowCount && !shift) ) ? false : $val
		}
		static public function get forward():Boolean 					{ return allowMovement( _s_forward ) }
		static public function get backward():Boolean 					{ return allowMovement( _s_backward ) }
		static public function get leftSlide():Boolean 					{ return allowMovement( _s_left ) }
		static public function get rightSlide():Boolean 				{ return allowMovement( _s_right ) }
		static public function get up():Boolean 						{ return allowMovement( _s_up ) }
		static public function get down():Boolean 						{ return allowMovement( _s_down ) }
		static public function get ctrl():Boolean 						{ return _s_ctrl; }
		static public function get shift():Boolean 						{ return _s_shift; }
		static public function get alt():Boolean 						{ return _s_alt; }
		static public function get active():Boolean						{ return _s_active; }
		static public function set active($val:Boolean):void			{ _s_active = $val; }
		
		public function MouseKeyboardHandler()  {}
		
		static public function fullScreenEvent(event:FullScreenEvent):void { 
			if ( event.fullScreen )
				Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove );
			else if ( !event.fullScreen )
				Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove );
		}
		
		// this is only used in full screen mode
		static private function onMove( event: MouseEvent) : void {
			_s_x += event.movementX;
			_s_y += event.movementY;
		}
		
		static public function getMouseXChange():int {
			if ( (Globals.openWindowCount || Log.showing) && !MouseKeyboardHandler.shift )
				return 0;
				
			var val:Number = 0;
			if ( Globals.g_app.stage.mouseLock ) {
				val = _s_x * 50;
				_s_x = 0;
			}
			else
				val = Globals.g_app.stage.mouseX - Globals.g_app.stage.stageWidth / 2;

			return val ;
		}
		
		static public function getMouseYChange():int {
			if ( (Globals.openWindowCount || Log.showing)  && !MouseKeyboardHandler.shift )
				return 0;
				
			var val:Number = 0;
			if ( Globals.g_app.stage.mouseLock ) {
				val = _s_y * 50;
				_s_y = 0;
			}
			else
				val = Globals.g_app.stage.mouseY - Globals.g_app.stage.stageHeight / 2;
				
			return val;
		}
		
		static private function addInputListeners():void {
			if ( false == _s_handlersAdded ) {
				_s_handlersAdded = true;
				Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
				Globals.g_app.stage.addEventListener( FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
				RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, regionLoadBegin );
				RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, regionLoadComplete );
			}
		}
		
		static private function regionLoadComplete(e:RegionEvent):void  {
			active = true;
		}
		
		static private function regionLoadBegin(e:RegionEvent):void  {
			active = false;
		}
		
		static private function removeInputListeners():void {
			if ( true == _s_handlersAdded ) {
				_s_handlersAdded = false;
				Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
				Globals.g_app.stage.removeEventListener( FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
				RegionEvent.removeListener( RegionEvent.LOAD_COMPLETE, regionLoadBegin );
				RegionEvent.removeListener( RegionEvent.LOAD_COMPLETE, regionLoadComplete );
			}
		}
		
		static public function init():void  { addInputListeners(); }
		
		static public function reset():void {
			_s_forward = false;		
			_s_backward = false;			
			_s_left = false;			
			_s_right = false;			
			_s_up = false;			
			_s_down = false;			
			_s_ctrl = false;			
			_s_shift = false;			
			_s_alt = false;			
		}
		
		static private function keyDown( $ke:KeyboardEvent):void {
			processKey( $ke, true );
			
			//if ( Keyboard.HOME == $ke.keyCode ) 									resetCamera();
			//if ( Keyboard.KEYNAME_BREAK == $ke.keyCode ) 							resetPosition()
		}
		
		static private function keyUp( $ke:KeyboardEvent ):void  {
			processKey( $ke, false );
		}
		
		static private function processKey( $ke:KeyboardEvent, $setter:Boolean):void  {
			switch ($ke.keyCode) {
				case Keyboard.CONTROL: 					_s_ctrl = $setter; break;
				case Keyboard.SHIFT: 					_s_shift = $setter; 
				case Keyboard.ALTERNATE: 				_s_alt = $setter; break;
				case Keyboard.Q: 						_s_down = $setter; break;
				case Keyboard.E: case Keyboard.SPACE:	_s_up = $setter; break;
				case Keyboard.W: case Keyboard.UP: 		_s_forward = $setter; break;
				// individual use case need to disable backward
				case Keyboard.S: case Keyboard.DOWN: 	_s_backward = $setter; break;
				case Keyboard.A: case Keyboard.LEFT: 	_s_left = $setter; break;
				case Keyboard.D: case Keyboard.RIGHT: 	_s_right = $setter; break;
			}
		}
	}
}