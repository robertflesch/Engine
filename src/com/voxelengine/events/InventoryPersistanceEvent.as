/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event;
import flash.events.EventDispatcher;

import flash.utils.ByteArray;
import playerio.DatabaseObject;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class InventoryPersistanceEvent extends PersistanceEvent
{
	private var _guid:String;
	private var _dbo:DatabaseObject;
	private var _ba:ByteArray;
	
	public function get guid():String  { return _guid; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function get ba():ByteArray { return _ba; }

	// This acts as a two way conduit passing info to the db and retrieving DB objects from it.
	public function InventoryPersistanceEvent( $type:String, $guid:String, $dbo:DatabaseObject = null, $ba:ByteArray = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
		_dbo = $dbo;
		_ba = $ba;
	}
	
	public override function clone():Event
	{
		return new InventoryPersistanceEvent(type, _guid, _dbo, _ba, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " Inventory: " + ( _dbo ? _dbo.toString(): "no database object" );
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

	static public function dispatch( $event:InventoryPersistanceEvent) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
	
	
}
}
