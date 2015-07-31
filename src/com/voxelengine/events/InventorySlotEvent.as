/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import flash.events.Event;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class InventorySlotEvent extends Event
{
	static public const INVENTORY_SLOT_CHANGE:String  			= "INVENTORY_SLOT_CHANGE";
	static public const INVENTORY_DEFAULT_REQUEST:String  		= "INVENTORY_DEFAULT_REQUEST";
	static public const INVENTORY_DEFAULT_RESPONSE:String  		= "INVENTORY_DEFAULT_RESPONSE";
	
	private var _ownerGuid:String; // Guid of model which is implementing this action
	private var _slotId:int;	  // Voxel Type ID
	private var _data:*;
	
	public function InventorySlotEvent( $type:String, $ownerGuid:String, $slotId:int, $data:*, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_ownerGuid = $ownerGuid;
		_slotId = $slotId;
		_data = $data;
	}
	
	public override function clone():Event
	{
		return new InventorySlotEvent( type, _ownerGuid, _slotId, _data, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "slotId", "data" );
	}
	
	public function get ownerGuid():String { return _ownerGuid; }
	public function get slotId():int { return _slotId; }
	public function get data():ObjectInfo { return _data; }
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:InventorySlotEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
