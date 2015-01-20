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
	public class InventoryVoxelEvent extends Event
	{
		static public const INVENTORY_VOXEL_INCREMENT:String  		= "INVENTORY_VOXEL_INCREMENT";
		static public const INVENTORY_VOXEL_DECREMENT:String  		= "INVENTORY_VOXEL_DECREMENT";
		static public const INVENTORY_VOXEL_COUNT_REQUEST:String  	= "INVENTORY_VOXEL_COUNT_REQUEST";
		static public const INVENTORY_VOXEL_COUNT_RESULT:String  	= "INVENTORY_VOXEL_COUNT_RESULT";
//		static public const INVENTORY_PRIM_REMOVE:String  			= "INVENTORY_VOXEL_REMOVE";
		
		private var _id:int;
		private var _count:int;
		
		public function InventoryVoxelEvent( $type:String, $id:int, $count:int, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_id = $id;
			_count = $count;
		}
		
		public override function clone():Event
		{
			return new InventoryVoxelEvent( type, _id, _count, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("InventoryEvent", "bubbles", "cancelable") + " InventoryPrim type: " + _id + " count: " + _count;
		}
		
		public function get id():int 
		{
			return _id;
		}
		
		public function get count():int 
		{
			return _count;
		}
		
		
		
	}
}
