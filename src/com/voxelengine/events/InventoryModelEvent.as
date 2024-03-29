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
public class InventoryModelEvent extends Event
{
	static public const INVENTORY_MODEL_LIST_REQUEST:String  		= "INVENTORY_MODEL_LIST_REQUEST";
	static public const INVENTORY_MODEL_LIST_RESULT:String  		= "INVENTORY_MODEL_LIST_RESULT";

	static public const INVENTORY_MODEL_CHANGE:String  				= "INVENTORY_MODEL_CHANGE";
	
	static public const INVENTORY_MODEL_COUNT_REQUEST:String  		= "INVENTORY_MODEL_COUNT_REQUEST";
	static public const INVENTORY_MODEL_COUNT_RESULT:String  		= "INVENTORY_MODEL_COUNT_RESULT";
	
	private var _networkId:String; // Guid of model which is implementing this action
	private var _itemGuid:String;
	private var _result:*;
	
	public function get networkId():String { return _networkId; }
	public function get itemGuid():String { return _itemGuid; }
	
	public function get result():* { return _result; }

	public function InventoryModelEvent( $type:String, $ownerGuid:String, $itemGuid:String, $result:*, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_networkId = $ownerGuid;
		_itemGuid = $itemGuid;
		_result = $result;
	}
	
	public override function clone():Event
	{
		return new InventoryModelEvent( type, _networkId, _itemGuid, _result, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryEvent", "bubbles", "cancelable") + " ownerGuid: " + _networkId + " itemGuid: " + _itemGuid + " result: " + _result;
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

	static public function dispatch( $event:InventoryModelEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
