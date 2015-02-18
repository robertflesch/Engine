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
public class InventoryEvent extends Event
{
	static public const INVENTORY_RESPONSE:String  		= "INVENTORY_RESPONSE";
	static public const INVENTORY_REQUEST:String  		= "INVENTORY_REQUEST";
	static public const INVENTORY_LOADED:String  		= "INVENTORY_LOADED";
	static public const INVENTORY_UNLOAD_REQUEST:String = "INVENTORY_UNLOAD_REQUEST";
	static public const INVENTORY_SLOT_REQUEST:String  	= "INVENTORY_SLOT_REQUEST";
	static public const INVENTORY_SLOT_RESULT:String  	= "INVENTORY_SLOT_RESULT";
	
	private var _ownerGuid:String; // Guid of model which is implementing this action
	private var _result:*;	
	
	public function get ownerGuid():String { return _ownerGuid; }
	public function get result():*  { return _result; }

	public function InventoryEvent( $type:String, $ownerGuid:String, $result:*, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_ownerGuid = $ownerGuid;
		_result = $result;
	}
	
	public override function clone():Event
	{
		return new InventoryEvent( type, _ownerGuid, _result, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " ownerGuid: " + _ownerGuid + " _result: " + _result;
	}
}
}
