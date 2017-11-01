/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class InventoryVoxelEvent extends Event
{
	static public const CHANGE:String  			= "CHANGE";
	static public const COUNT_REQUEST:String  	= "COUNT_REQUEST";
	static public const COUNT_RESULT:String  	= "COUNT_RESULT";
	static public const TYPES_REQUEST:String  	= "TYPES_REQUEST";
	static public const TYPES_RESULT:String  	= "TYPES_RESULT";
//		static public const INVENTORY_PRIM_REMOVE:String  			= "REMOVE";
	
	private var _networkId:String; // Guid of model which is implementing this action
	private var _typeId:int;	  // Voxel Type ID
	private var _result:*;
	
	public function InventoryVoxelEvent( $type:String, $ownerGuid:String, $typeId:int, $result:* )
	{
		super( $type );
		_networkId = $ownerGuid;
		_typeId = $typeId;
		_result = $result;
	}
	
	public override function clone():Event
	{
		return new InventoryVoxelEvent( type, _networkId, _typeId, _result);
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

	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

    static public function create( $type:String, $ownerGuid:String, $typeId:int, $result:* ):Boolean {
        return _eventDispatcher.dispatchEvent( new InventoryVoxelEvent( $type, $ownerGuid, $typeId, $result ) );
	}


	///////////////// Event handler interface /////////////////////////////
}	
}
