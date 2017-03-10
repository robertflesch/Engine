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

public class PlayerIOPersistenceEvent extends Event
{
	static public const PERSISTANCE_NO_CLIENT:String	= "PERSISTANCE_NO_CLIENT";
	static public const PERSISTANCE_NO_DB:String		= "PERSISTANCE_NO_DB";
	
	public function PlayerIOPersistenceEvent($type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
	
	public override function clone():Event
	{
		return new PlayerIOPersistenceEvent(type, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("PersistenceEvent", "bubbles", "cancelable");
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistence messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:PlayerIOPersistenceEvent) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
