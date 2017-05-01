/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel 
{
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.GUI.WindowSplash;
import flash.events.KeyboardEvent;
import flash.events.FullScreenEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import com.voxelengine.Globals;
import com.voxelengine.Log;

/*
 * All keyboard and mouse management should go thru here
 */
public class MouseKeyboardHandler
{
	static private var _s_active:Boolean;
	static public function get active():Boolean						{ return _s_active; }
	static public function set active($val:Boolean):void			{ _s_active = $val; }

	static private var _s_forward:Boolean;
	static public function get forward():Boolean 					{ return allowMovement( _s_forward ) }
	static private var _s_backward:Boolean;
	static public function get backward():Boolean 					{ return allowMovement( _s_backward ) }
	static private var _s_left:Boolean;
	static public function get leftSlide():Boolean 					{ return allowMovement( _s_left ) }
	static private var _s_right:Boolean;
	static public function get rightSlide():Boolean 				{ return allowMovement( _s_right ) }
	static private var _s_up:Boolean;
	static public function get up():Boolean 						{ return allowMovement( _s_up ) }
	static private var _s_down:Boolean;
	static public function get down():Boolean 						{ return allowMovement( _s_down ) }

	static private var _s_ctrl:Boolean;
	static public function get isCtrlKeyDown():Boolean 				{ return _s_ctrl; }
	static private var _s_shift:Boolean;
	static public function get isShiftKeyDown():Boolean 			{ return _s_shift; }
	static private var _s_alt:Boolean;
	static public function get isAltKeyDown():Boolean 				{ return _s_alt; }

	static private var _s_leftMouseDown:Boolean;
	static public function get isLeftMouseDown():Boolean			{ return _s_leftMouseDown }

	// Enable / Disable Keys
	static private var _s_leftTurnEnabled:Boolean 					= true;
	static public function get leftTurnEnabled():Boolean 				{ return _s_leftTurnEnabled; }
	static public function set leftTurnEnabled(value:Boolean):void 		{ _s_leftTurnEnabled = value; }
	static private var _s_rightTurnEnabled:Boolean 					= true;
	static public function get rightTurnEnabled():Boolean 				{ return _s_rightTurnEnabled; }
	static public function set rightTurnEnabled(value:Boolean):void 	{ _s_rightTurnEnabled = value; }

	static private var _s_handlersAdded:Boolean 					= false;

	public function MouseKeyboardHandler()  {}


	static private function allowMovement( $val:Boolean ):Boolean {
		return (( Log.showing ) || (Globals.openWindowCount && !isShiftKeyDown) ) ? false : $val
	}

	static public function fullScreenEvent(event:FullScreenEvent):void {
		if ( event.fullScreen )
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove );
		else if ( !event.fullScreen )
			Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove );
	}

	// this is only used in full screen mode
	static private var _s_x:Number = 0;
	static private var _s_y:Number = 0;
	static private function onMove( event: MouseEvent) : void {
		_s_x += event.movementX;
		_s_y += event.movementY;
	}

	static public function getMouseXChange():int {
		if ( (Globals.openWindowCount || Log.showing) && !MouseKeyboardHandler.isShiftKeyDown )
			return 0;

		if ( WindowSplash.isActive )
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
		if ( (Globals.openWindowCount || Log.showing)  && !MouseKeyboardHandler.isShiftKeyDown )
			return 0;

		if ( WindowSplash.isActive )
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
			Globals.g_app.stage.addEventListener(FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_DOWN, leftMouseDownEvent );
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_UP, leftMouseUpEvent );
			Globals.g_app.stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, leftMouseUpEvent );
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			RegionEvent.addListener( RegionEvent.LOAD_BEGUN, loadBegun );
			RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, loadComplete );
		}
	}

	static public function leftMouseDownEvent( $me:MouseEvent ):void {
//		Log.out( "MKH.leftMouseDownEvent target: " + $me ? String($me.target) : "No target" );
		_s_leftMouseDown = true;
	}
	static public function leftMouseUpEvent( $me:MouseEvent ):void {
//		Log.out( "MKH.leftMouseUpEvent target: " + $me ? String($me.target) : "No target" );
		CursorOperationEvent.create( CursorOperationEvent.ACTIVATE );
		_s_leftMouseDown = false;
	}

	static private function removeInputListeners():void {
		if ( true == _s_handlersAdded ) {
			_s_handlersAdded = false;
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
			Globals.g_app.stage.removeEventListener(FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED, fullScreenEvent );
			Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, leftMouseDownEvent );
			Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_UP, leftMouseUpEvent );
			Globals.g_app.stage.removeEventListener(MouseEvent.RELEASE_OUTSIDE, leftMouseUpEvent );
			RegionEvent.removeListener( RegionEvent.LOAD_BEGUN, loadBegun );
			RegionEvent.removeListener( RegionEvent.LOAD_COMPLETE, loadComplete );
		}
	}

	static private function loadBegun(e:RegionEvent):void  { active = false }
	static private function loadComplete(e:RegionEvent):void  { active = true }

	static public function init():void  {
		addInputListeners(); }

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

	static private function keyDown( $ke:KeyboardEvent):void { processKey( $ke, true );
		//if ( Keyboard.HOME == $ke.keyCode ) 									resetCamera();
		//if ( Keyboard.KEYNAME_BREAK == $ke.keyCode ) 							resetPosition()
	}
	static private function keyUp( $ke:KeyboardEvent ):void  { processKey( $ke, false ); }
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