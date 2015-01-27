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

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class InventoryModelEvent extends Event
{
	static public const INVENTORY_MODEL_INCREMENT:String  		= "INVENTORY_MODEL_INCREMENT";
	//static public const INVENTORY_MODEL_REMOVE:String  	= "INVENTORY_MODEL_REMOVE";
	static public const INVENTORY_MODEL_DECREMENT:String  		= "INVENTORY_MODEL_DECREMENT";
	static public const INVENTORY_MODEL_COUNT_REQUEST:String  	= "INVENTORY_MODEL_COUNT_REQUEST";
	static public const INVENTORY_MODEL_COUNT_RESULT:String  	= "INVENTORY_MODEL_COUNT_RESULT";
	
	private var _ownerGuid:String; // Guid of model which is implementing this action
	private var _itemGuid:String;
	private var _count:int;
	
	public function get ownerGuid():String { return _ownerGuid; }
	public function get itemGuid():String { return _itemGuid; }
	
	public function get count():int { return _count; }

	public function InventoryModelEvent( $type:String, $ownerGuid:String, $itemGuid:String, $count:int, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_ownerGuid = $ownerGuid;
		_itemGuid = $itemGuid;
		_count = $count;
	}
	
	public override function clone():Event
	{
		return new InventoryModelEvent( type, _ownerGuid, _itemGuid, _count, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " ownerGuid: " + _ownerGuid + " itemGuid: " + _itemGuid + " count: " + _count;
	}
}
}
