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
	static public const INVENTORY_VOXEL_CHANGE:String  			= "INVENTORY_VOXEL_CHANGE";
	static public const INVENTORY_VOXEL_COUNT_REQUEST:String  	= "INVENTORY_VOXEL_COUNT_REQUEST";
	static public const INVENTORY_VOXEL_COUNT_RESULT:String  	= "INVENTORY_VOXEL_COUNT_RESULT";
	static public const INVENTORY_VOXEL_TYPES_REQUEST:String  	= "INVENTORY_VOXEL_TYPES_REQUEST";
	static public const INVENTORY_VOXEL_TYPES_RESULT:String  	= "INVENTORY_VOXEL_TYPES_RESULT";
//		static public const INVENTORY_PRIM_REMOVE:String  			= "INVENTORY_VOXEL_REMOVE";
	
	private var _networkId:String; // Guid of model which is implementing this action
	private var _typeId:int;	  // Voxel Type ID
	private var _result:*;
	
	public function InventoryVoxelEvent( $type:String, $ownerGuid:String, $typeId:int, $result:*, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_networkId = $ownerGuid;
		_typeId = $typeId;
		_result = $result;
	}
	
	public override function clone():Event
	{
		return new InventoryVoxelEvent( type, _networkId, _typeId, _result, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " InventoryPrim type: " + _typeId + " result: " + _result;
	}
	
	public function get typeId():int 
	{
		return _typeId;
	}
	
	public function get result():* 
	{
		return _result;
	}
	
	public function get networkId():String { return _networkId; }
}
}
