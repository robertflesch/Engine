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
public class InventoryInterfaceEvent extends Event
{
	static public const DISPLAY:String  = "DISPLAY";
	static public const HIDE:String  	= "HIDE";
	static public const CLOSE:String  	= "CLOSE";
	
	private var _owner:String; // Guid of model which is implementing this action
	private var _image:String; // Guid of model which is implementing this action
	public function get owner():String { return _owner; }
	public function get image():String { return _image; }

	public function InventoryInterfaceEvent( $type:String, $owner:String, $image:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_owner = $owner;
		_image = $image;
	}
	
	public override function clone():Event
	{
		return new InventoryInterfaceEvent( type, _owner, _image, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("InventoryInterfaceEvent", "owner", "image" );
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

	static public function dispatch( $event:InventoryInterfaceEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
