/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
	static public const SLOT_CHANGE:String  			= "SLOT_CHANGE";
	static public const DEFAULT_REQUEST:String  		= "DEFAULT_REQUEST";
	static public const DEFAULT_RESPONSE:String  		= "DEFAULT_RESPONSE";
	
	private var _ownerGuid:String; 		// Guid of model which owns the actionbar
	private var _instanceGuid:String; 	// Guid of model which is implementing this action
	private var _slotId:int;	  		// Slot that this goes in, -1 for first empty slot
	private var _data:*;
	
	public function InventorySlotEvent( $type:String, $ownerGuid:String, $instanceGuid:String, $slotId:int, $data:* )
	{
		super( $type );
		_ownerGuid = $ownerGuid;
		_instanceGuid = $instanceGuid;
		_slotId = $slotId;
		_data = $data;
	}
	
	public override function clone():Event
	{
		return new InventorySlotEvent( type, _ownerGuid, _instanceGuid, _slotId, _data );
	}
   
	public override function toString():String
	{
		return formatToString("InventorySlotEvent", "slotId", "data" );
	}
	
	public function get ownerGuid():String { return _ownerGuid; }
	public function get instanceGuid():String { return _instanceGuid; }
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

	static public function create( $type:String, $ownerGuid:String, $instanceGuid:String, $slotId:int, $data:* ) : Boolean {
		return _eventDispatcher.dispatchEvent( new InventorySlotEvent( $type, $ownerGuid, $instanceGuid, $slotId, $data ) );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
