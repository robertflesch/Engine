/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.worldmodel.TypeInfo;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

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
	static public const INVENTORY_MODEL:int = 1;
	static public const INVENTORY_VOXEL:int = 2;
	static public const INVENTORY_ANIMATION:int = 3;
	static public const INVENTORY_RECIPE:int = 4;
	static public const INVENTORY_FRIEND:int = 5;
	

	static private var _models:Array = new Array();
	static private var _voxels:Array = new Array();
	
	public function InventoryManager() {
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_INCREMENT,		inventoryModelIncrement );
		addEventListener( InventoryModelEvent.INVENTORY_MODEL_DECREMENT, 		inventoryModelDecrement );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_INCREMENT, 		inventoryVoxelIncrement );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_DECREMENT, 		inventoryVoxelDecrement );
		addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST,	inventoryVoxelTypes );
		
		addModelTestData();
		addVoxelTestData();
	}
	
	// This returns an Array which holds the typeId and the count of those voxels
	private function inventoryVoxelTypes(e:InventoryVoxelEvent):void 
	{
		const cat:String = (e.result as String).toUpperCase();
		if ( cat == "ALL" ) {
			dispatchEvent( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, -1, _voxels ) );
			return;
		}
			
		var result:Array = [];
		var item:TypeInfo;
		// This iterates thru the keys
		for (var key:String in _voxels) {
			var typeId:int = key as int;
			if ( cat == Globals.Info[typeId].category )
				result[key]	= _voxels[key];
		}

		dispatchEvent( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, -1, result ) );
	}
	
	private function inventoryVoxelCount(e:InventoryVoxelEvent):void 
	{
		var voxelId:int = e.id;
		var voxelCount:int = _voxels[voxelId];
		dispatchEvent( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelId, voxelCount ) );
	}
	
	private function inventoryModelCount(e:InventoryModelEvent):void 
	{
		var modelId:String = e.guid;
		var modelCount:int = _models[modelId];
		dispatchEvent( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, modelId, modelCount ) );
	}
	
	private function addModelTestData():void {
		_models["Pick"] = 1;
		_models["Shovel"] = 1;
	}
	
	private function addVoxelTestData():void {
		_voxels[Globals.STONE] = 1234;
		_voxels[Globals.DIRT] = 432;
	}
	
	private function inventoryModelIncrement(e:InventoryModelEvent):void 
	{
		
	}
	
	private function inventoryModelDecrement(e:InventoryModelEvent):void 
	{
		
	}
	
	private function inventoryVoxelDecrement(e:InventoryVoxelEvent):void 
	{
		var count:int = _voxels[e.id];
		var resultCount:int = int( e.result );
		Log.out( "InventoryManager.inventoryVoxelDecrement - trying to remove id: " + e.id + " of count: " + resultCount + " current count: " + count );
		if ( 0 < count && resultCount <= count ) {
			count -= resultCount;
			_voxels[e.id] = count;
			Log.out( "InventoryManager.inventoryVoxelDecrement - removed : " + resultCount );
			return;
		}
			
		Log.out( "InventoryManager.inventoryVoxelDecrement - FAILED to remove a type has less then request count - id: " + e.id + " of count: " + resultCount + " current count: " + count, Log.ERROR );
	}
	
	private function inventoryVoxelIncrement(e:InventoryVoxelEvent):void 
	{
		
	}
	
	static public function get models():Array
	{
		return _models;
	}
}
}