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

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class CursorShapeEvent extends Event
{
	static public const SQUARE:String 			= "SQUARE";
	static public const SPHERE:String 			= "SPHERE";		
	static public const CYLINDER:String 		= "CYLINDER";		
	static public const MODEL_AUTO:String 		= "MODEL_AUTO";		

	public function CursorShapeEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
	
	public override function clone():Event
	{
		return new CursorShapeEvent(type, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("CursorEvent", "type", "bubbles", "cancelable");
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

	static public function dispatch( $event:CursorShapeEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
