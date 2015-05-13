/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.inventory.ObjectModel;
import flash.events.Event;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class CursorSizeEvent extends Event
{
	static public	const GROW:String 			= "GROW";
	static public	const SHRINK:String 		= "SHRINK";
	static public	const SET:String 			= "SET";

	private var _size:int
	public function get size():int  { return _size; }
	
	public function CursorSizeEvent( $type:String, $size:int = 4, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_size	= $size;
	}
	
	public override function clone():Event
	{
		return new CursorSizeEvent(type, _size, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("CursorEvent", "size", "bubbles", "cancelable");
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

	static public function dispatch( $event:CursorSizeEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	
	///////////////// Event handler interface /////////////////////////////
}
}
