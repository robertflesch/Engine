/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.events.InventoryEvent;
import flash.events.Event;
import flash.events.EventDispatcher;

import com.voxelengine.Globals;
import com.voxelengine.Log;

	/**
	 * The inventory manager is a static object that hold the inventory of different objects
	 * It also acts as the event dispatcher for InventoryEvents
	 * @author Bob
	 */
	
	 
public class InventoryManager
{
	// There is still some confustion here, do I use network id? that would mean only avatars can have intentory
	// really I want any model to be able to have inventory. so this can be networkid OR guid ?? both are unique.
	static private var  _s_inventoryByGuid:Array = [];
	
	public static function save():void {
		for each ( var inventory:Inventory in _s_inventoryByGuid )
			if ( null != inventory && inventory.networkId != "player" )
				inventory.save();
	}
	
	public static function init():void {
		// This creates a inventory object for login.
		objectInventoryGet("player");	
		addListener( InventoryEvent.INVENTORY_UNLOAD_REQUEST, unloadInventory );
	}
	
	static private function unloadInventory(e:InventoryEvent):void 
	{
		var inventory:Inventory = _s_inventoryByGuid[ e.ownerGuid ];
		if ( inventory ) {
			var tempArray:Array = [];
			for each ( var inv:Inventory in _s_inventoryByGuid )
			{
				if ( e.ownerGuid == inv.networkId ) {
					_s_inventoryByGuid[ e.ownerGuid ] = null;
					inv.unload();
					// could I just use a delete here, rather then creating new dictionary? See Dictionary class for details - RSF
				}
				else
				{
					if ( inv )
						tempArray[inv.networkId] = inv;
					else
						Log.out( "InventoryManager.unloadInventory - Null found", Log.ERROR );
				}
			}
			_s_inventoryByGuid = null;
			_s_inventoryByGuid = tempArray;	
		}
	}
	
	static public function objectInventoryGet( $ownerGuid:String ):Inventory {
		var inventory:Inventory = _s_inventoryByGuid[$ownerGuid];
		if ( null == inventory && null != $ownerGuid ) {
			//Log.out( "InventoryManager.objectInventoryGet creating inventory for: " + $ownerGuid , Log.WARN );
			inventory = new Inventory( $ownerGuid );
			_s_inventoryByGuid[$ownerGuid] = inventory;
			inventory.load();
		}
		
		return inventory;	
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
	
	static public function dispatch( $event:Event) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
}
}
