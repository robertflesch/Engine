/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import flash.events.EventDispatcher;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventoryVoxelEvent;

	/**
	 * ...
	 * @author Bob
	 */
	
	 
public class InventoryManager extends EventDispatcher
{
//	static private var _initialized:Boolean;
	
	static private var _models:Vector.<InventoryModel> = new Vector.<InventoryModel>();
	static private var _voxels:Vector.<InventoryVoxel> = new Vector.<InventoryVoxel>();
	
	public function InventoryManager() {
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_ADD, inventoryModelAdd );
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_DELETE, inventoryModelDelete );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_ADD, inventoryVoxelAdd );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_DELETE, inventoryVoxelDelete );
	}
	
	private function inventoryModelDelete(e:InventoryModelEvent):void 
	{
		
	}
	
	private function inventoryVoxelDelete(e:InventoryVoxelEvent):void 
	{
		
	}
	
	private function inventoryVoxelAdd(e:InventoryVoxelEvent):void 
	{
		
	}
	
	private function inventoryModelAdd(e:InventoryModelEvent):void 
	{
		
	}
	
	static public function get models():Vector.<InventoryModel> 
	{
		return _models;
	}
}
}