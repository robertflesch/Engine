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
	// Asks for the inventory
	static public const INVENTORY_REQUEST:String  		= "INVENTORY_REQUEST";
	// Returns the inventory object
	static public const INVENTORY_RESPONSE:String  		= "INVENTORY_RESPONSE";
	
	// Save request no response needed
	static public const INVENTORY_SAVE_REQUEST:String  	= "INVENTORY_SAVE_REQUEST";
	// User/NP is logging/leaving system out, so remove inventory
	static public const INVENTORY_UNLOAD_REQUEST:String = "INVENTORY_UNLOAD_REQUEST";
	
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
