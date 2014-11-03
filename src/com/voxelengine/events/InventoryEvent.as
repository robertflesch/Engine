/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import com.voxelengine.worldmodel.inventory.InventoryObject;
	import flash.events.Event;
	
	import com.voxelengine.worldmodel.inventory.Inventory;
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class InventoryEvent extends Event
	{
		static public const INVENTORY_ADD:String  		= "INVENTORY_ADD";
		static public const INVENTORY_REMOVE:String  	= "INVENTORY_REMOVE";
		static public const INVENTORY_DELETE:String  	= "INVENTORY_DELETE";
		static public const INVENTORY_SAVE:String  		= "INVENTORY_SAVE";
		
		private var _item:InventoryObject;
		private var _guid:String;
		
		public function get item():InventoryObject { return _item; }

		public function InventoryEvent( $type:String, $guid:String, $item:InventoryObject, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_item = $item;
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new InventoryEvent(type, _guid, _dbo, _ba, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("InventoryEvent", "bubbles", "cancelable") + " InventoryObject: " + _item.toString();
		}
		
		
		
	}
}
