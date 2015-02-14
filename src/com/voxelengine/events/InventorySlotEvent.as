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

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class InventorySlotEvent extends Event
{
	static public const INVENTORY_SLOT_CHANGE:String  			= "INVENTORY_SLOT_CHANGE";
	
	private var _ownerGuid:String; // Guid of model which is implementing this action
	private var _slotId:int;	  // Voxel Type ID
	private var _item:ObjectInfo;
	
	public function InventorySlotEvent( $type:String, $ownerGuid:String, $slotId:int, $item:ObjectInfo, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_ownerGuid = $ownerGuid;
		_slotId = $slotId;
		_item = $item;
	}
	
	public override function clone():Event
	{
		return new InventorySlotEvent( type, _ownerGuid, _slotId, _item, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " Inventory slot: " + _slotId + " item: " + _item;
	}
	
	public function get ownerGuid():String { return _ownerGuid; }
	
	public function get slotId():int 
	{
		return _slotId;
	}
	
	public function get item():ObjectInfo 
	{
		return _item;
	}
}
}
