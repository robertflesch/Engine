/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.display3D.Context3D;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class ContextEvent extends Event
{
	static public const DISPOSED:String			= "DISPOSED";
	static public const ACQUIRED:String			= "ACQUIRED";
	
	private var _context3D:Context3D;
	public function get context3D():Context3D  { return _context3D; }
	
	public function ContextEvent( $type:String, $context:Context3D, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
		_context3D = $context;
	}
	
	public override function clone():Event {
		return new ContextEvent(type, _context3D, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString("ContextEvent", "context3D", "bubbles", "cancelable");
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:ContextEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
}
}
