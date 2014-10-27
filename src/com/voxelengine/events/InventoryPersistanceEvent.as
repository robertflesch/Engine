/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	
	import com.voxelengine.worldmodel.inventory.Inventory;
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class InventoryPersistanceEvent extends Event
	{
		static public const INVENTORY_LOAD_REQUEST:String  	= "INVENTORY_LOAD_REQUEST";
		static public const INVENTORY_LOAD_SUCCEED:String  	= "INVENTORY_LOAD_SUCCEED";
		static public const INVENTORY_LOAD_FAILED:String  	= "INVENTORY_LOAD_FAILED";
		
		static public const INVENTORY_SAVE_REQUEST:String  	= "INVENTORY_SAVE_REQUEST";
		static public const INVENTORY_CREATE_SUCCEED:String	= "INVENTORY_CREATE_SUCCEED";
		static public const INVENTORY_SAVE_SUCCEED:String  	= "INVENTORY_SAVE_SUCCEED";
		static public const INVENTORY_CREATE_FAILED:String	= "INVENTORY_CREATE_FAILED";
		static public const INVENTORY_SAVE_FAILED:String  	= "INVENTORY_SAVE_FAILED";
		
		private var _guid:String;
		private var _dbo:DatabaseObject;
		private var _ba:ByteArray;
		
		public function get guid():String  { return _guid; }
		public function get dbo():DatabaseObject { return _dbo; }
		public function get ba():ByteArray { return _ba; }

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
		
		
		
	}
}
