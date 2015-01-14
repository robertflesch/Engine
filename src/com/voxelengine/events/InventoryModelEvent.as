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
		static public const INVENTORY_MODEL_ADD:String  		= "INVENTORY_MODEL_ADD";
		//static public const INVENTORY_MODEL_REMOVE:String  	= "INVENTORY_MODEL_REMOVE";
		static public const INVENTORY_MODEL_DELETE:String  		= "INVENTORY_MODEL_DELETE";
		
		private var _guid:String;
		
		public function get guid():String { return _guid; }

		public function InventoryModelEvent( $type:String, $guid:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new InventoryModelEvent( type, _guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("InventoryEvent", "bubbles", "cancelable") + " guid: " + _guid;
		}
		
		
		
	}
}
