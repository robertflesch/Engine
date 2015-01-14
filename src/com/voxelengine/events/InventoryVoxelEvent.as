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
		static public const INVENTORY_VOXEL_ADD:String  		= "INVENTORY_VOXEL_ADD";
//		static public const INVENTORY_PRIM_REMOVE:String  		= "INVENTORY_VOXEL_REMOVE";
		static public const INVENTORY_VOXEL_DELETE:String  		= "INVENTORY_VOXEL_DELETE";
		
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
		
		
		
	}
}
