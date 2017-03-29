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

public class TriggerEvent extends Event
{
	static public const INSIDE:String 			= "INSIDE";
	static public const OUTSIDE:String 			= "OUTSIDE";
	
	private var _instanceGuid:String = "";

	public function get instanceGuid():String { return _instanceGuid; }
	
	public function TriggerEvent( $type:String, $owner:String, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
		_instanceGuid = $owner;
	}
	
	public override function clone():Event {
		return new TriggerEvent(type, _instanceGuid, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString( "type", "instanceGuid" );
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all trigger messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function create( $type:String, $owner:String ) : Boolean {
		return _eventDispatcher.dispatchEvent( new TriggerEvent( $type, $owner ) );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
