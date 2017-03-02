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
	static public const REBUILD:String			= "REBUILD";

	private var _context3D:Context3D;
	public function get context3D():Context3D  { return _context3D; }
	
	public function ContextEvent( $type:String, $context:Context3D ) {
		super( $type );
		_context3D = $context;
	}
	
	public override function clone():Event {
		return new ContextEvent(type, _context3D);
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

	static public function create( $type:String, $context:Context3D ) : Boolean {
		return _eventDispatcher.dispatchEvent( new ContextEvent( $type, $context ) );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
}
}
