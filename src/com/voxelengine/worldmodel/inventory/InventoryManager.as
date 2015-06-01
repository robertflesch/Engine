/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * The inventory manager is a static object that hold the inventory of different objects
	 * It also acts as the event dispatcher for InventoryEvents
	 * @author Bob
	 */
	
	 
public class InventoryManager
{
	// There is still some confustion here, do I use network id? that would mean only avatars can have intentory
	// really I want any model to be able to have inventory. so this is instanceInfo.instanceGuid.
	static private var  _s_inventoryByGuid:Array = [];
	
	static public function init():void {
		// This creates a inventory object for login.
//		objectInventoryGet("player");	
		InventoryEvent.addListener( InventoryEvent.UNLOAD_REQUEST, unloadInventory );
		InventoryEvent.addListener( InventoryEvent.REQUEST, requestInventory );
		InventoryEvent.addListener( InventoryEvent.SAVE_REQUEST, save );
		InventoryEvent.addListener( InventoryEvent.DELETE, deleteInventory );
	}


	static private function save( e:InventoryEvent ):void {
		if ( Globals.online ) {
			for each ( var inventory:Inventory in _s_inventoryByGuid )
				if ( null != inventory && inventory.guid != "Player" )
					inventory.save();
		}
	}
	
	
	static private function requestInventory(e:InventoryEvent):void 
	{
		Log.out( "InventoryManager.requestInventory - OWNER: " + e.owner, Log.DEBUG );
		if ( e.owner == "Player" )
			return;
		var inv:Inventory = objectInventoryGet( e.owner );
		if ( inv && inv.loaded ) {
			Log.out( "InventoryManager.requestInventory - InventoryEvent.RESPONSE - OWNER: " + e.owner, Log.DEBUG );
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, e.owner, inv ) );
		}
	}
	
	static private function deleteInventory(e:InventoryEvent):void 
	{
		Log.out( "InventoryManager.deleteInventory - OWNER: " + e.owner, Log.DEBUG );
		var inv:Inventory = _s_inventoryByGuid[e.owner];
		if ( inv ) {
			Log.out( "InventoryManager.deleteInventory - InventoryEvent.DELETE - OWNER: " + e.owner, Log.DEBUG );
			inv.deleteInventory();
			_s_inventoryByGuid[e.owner] = null;
		}
	}
	
	static private function unloadInventory(e:InventoryEvent):void 
	{
		var inventory:Inventory = _s_inventoryByGuid[ e.owner ];
		if ( inventory ) {
			var tempArray:Array = [];
			for each ( var inv:Inventory in _s_inventoryByGuid )
			{
				if ( e.owner == inv.guid ) {
					_s_inventoryByGuid[ e.owner ] = null;
					inv.unload();
					// could I just use a delete here, rather then creating new dictionary? See Dictionary class for details - RSF
				}
				else
				{
					if ( inv )
						tempArray[inv.guid] = inv;
					else
						Log.out( "InventoryManager.unloadInventory - Null found", Log.ERROR );
				}
			}
			_s_inventoryByGuid = null;
			_s_inventoryByGuid = tempArray;	
		}
	}
	
	static private function objectInventoryGet( $ownerGuid:String ):Inventory {
		var inventory:Inventory = _s_inventoryByGuid[$ownerGuid];
		if ( null == inventory && null != $ownerGuid ) {
			//Log.out( "InventoryManager.objectInventoryGet building inventory object for: " + $ownerGuid , Log.WARN );
			inventory = new Inventory( $ownerGuid );
			_s_inventoryByGuid[$ownerGuid] = inventory;
			inventory.load();
		}
		
		return inventory;	
	}
}
}
