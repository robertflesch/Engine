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
public class InventoryEvent extends Event
{
	// Asks for the inventory
	static public const REQUEST:String  		= "REQUEST";
	// Returns the inventory object
	static public const RESPONSE:String  		= "RESPONSE";
	
	// Save request no response needed
	static public const SAVE_REQUEST:String  	= "SAVE_REQUEST";
	static public const SAVE_FORCE:String  		= "SAVE_FORCE";
	// User/NP is logging/leaving system out, so remove inventory
	static public const UNLOAD_REQUEST:String 	= "UNLOAD_REQUEST";
	
	static public const DELETE:String 			= "DELETE";

	private var _owner:String; // Guid of model which is implementing this action
	private var _result:*;	
	
	public function get owner():String { return _owner; }
	public function get result():*  { return _result; }

	public function InventoryEvent( $type:String, $owner:String, $result:*, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_owner = $owner;
		_result = $result;
	}
	
	public override function clone():Event
	{
		return new InventoryEvent( type, _owner, _result, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " ownerGuid: " + _owner + " _result: " + _result;
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

	static public function dispatch( $event:InventoryEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
