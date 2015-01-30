/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import flash.events.Event;
import flash.events.EventDispatcher;

import com.voxelengine.Globals;
import com.voxelengine.Log;

	/**
	 * ...
	 * @author Bob
	 */
	
	 
public class InventoryManager extends EventDispatcher
{
	private var  _inventoryByGuid:Array = [];
	
	private static var s_inventoryManager:InventoryManager;
	
	private static function get inventoryManager():InventoryManager { 
		if ( null == s_inventoryManager )
			s_inventoryManager = new InventoryManager(); 
			
		return s_inventoryManager;
	} 
	
	///////////////// Event handler interface /////////////////////////////

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		inventoryManager.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		inventoryManager.removeEventListener( $type, $listener, $useCapture );
	}
	
	static public function dispatch( $event:Event) : Boolean {
		return inventoryManager.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
	public function InventoryManager() {}
	
	static public function objectInventoryGet( $ownerGuid:String ):Inventory {
		var inventory:Inventory = inventoryManager._inventoryByGuid[$ownerGuid];
		if ( null == inventory && null != $ownerGuid ) {
			Log.out( "InventoryManager.objectInventoryGet creating inventory for: " + $ownerGuid , Log.WARN );
			inventory = new Inventory( $ownerGuid );
			inventoryManager._inventoryByGuid[$ownerGuid] = inventory;
			inventory.load();
		}
		
		return inventory;	
	}
}
}
