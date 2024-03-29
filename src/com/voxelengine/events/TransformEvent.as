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
 */
public class TransformEvent extends Event
{
	static public const INVALID:String					= "INVALID";
	
	static public const ENDED:String					= "ENDED";

	private var _guid:String;
	public function get guid():String { return _guid; }
	private var _name:String;
	public function get name():String { return _guid; }
	
	public function TransformEvent( $type:String, $guid:String, $name:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
		_name = $name;
	}
	
	public override function clone():Event
	{
		return new TransformEvent(type, _guid, _name, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("TransformEvent", "bubbles", "cancelable") + " guid: " + _guid + "  name: " + _name ;
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

	static public function dispatch( $event:TransformEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
	
}
}
