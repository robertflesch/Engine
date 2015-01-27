/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.worldmodel.ObjectInfo;
import com.voxelengine.worldmodel.TypeInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Network;

import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.InventorySlotEvent;

	/**
	 * ...
	 * @author Bob
	 */
	
	 
public class InventoryManager extends EventDispatcher
{
//	static private var _initialized:Boolean;
	static public const INVENTORY_MODEL:int = 1;
	static public const INVENTORY_VOXEL:int = 2;
	static public const INVENTORY_ANIMATION:int = 3;
	static public const INVENTORY_RECIPE:int = 4;
	static public const INVENTORY_FRIEND:int = 5;
	
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
	
	public function InventoryManager() {
		
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, 			voxelChange );
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_INCREMENT,		modelIncrement );
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_DECREMENT, 		modelDecrement );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST,	voxelCount );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST,	voxelTypes );
		
		addEventListener( InventorySlotEvent.INVENTORY_SLOT_CHANGE,	slotChange );
	}
	
	private function slotChange(e:InventorySlotEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.slotChange( e );
	}
	
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
	
	// This returns an Array which holds the typeId and the count of those voxels
	private function voxelTypes(e:InventoryVoxelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.voxelTypes( e );
	}
	
	private function voxelCount(e:InventoryVoxelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.voxelCount( e );
	}
	
	private function modelCount(e:InventoryModelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.modelCount( e );
		//var modelId:String = e.ownerGuid;
		//var modelCount:int = _models[modelId];
		//dispatchEvent( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, $ownerGuid, modelId, modelCount ) );
	}
	
	private function modelIncrement(e:InventoryModelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.modelIncrement( e );
	}
	
	private function modelDecrement(e:InventoryModelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.modelDecrement( e );
	}
	
	private function voxelChange(e:InventoryVoxelEvent):void 
	{
		var inventory:Inventory = objectInventoryGet( e.ownerGuid );
		if ( null != inventory )
			inventory.voxelChange( e );
	}
}
}
