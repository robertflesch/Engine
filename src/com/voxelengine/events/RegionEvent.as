/*==============================================================================
Copyright 2011-2014 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event;
import flash.events.EventDispatcher;

import com.voxelengine.worldmodel.Region;
/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class RegionEvent extends Event
{
	// request from persistance
	static public const REQUEST:String						= "REQUEST";
	
	// data or meta data about this region has changed
	static public const CHANGED:String						= "CHANGED";
	
	// dispatched when a region is unloaded
	static public const UNLOAD:String						= "UNLOAD";
	// tells the region manager to load this region
	static public const LOAD:String							= "LOAD";
	// dispatched after jobs for all process have been added
	static public const LOAD_BEGUN:String					= "LOAD_BEGUN";
	// tells the region manager this region had finished loading
	static public const LOAD_COMPLETE:String				= "LOAD_COMPLETE";
	
	// tells us the region manager has add this region from persistance
	static public const ADDED:String						= "ADDED";
	
	// tells the region manager to load this region
	static public const TYPE_REQUEST:String					= "TYPE_REQUEST";
	// the response to this is the loaded message
	
	// Used by the sandbox list and config manager to request a join of a server region
	static public const JOIN:String							= "JOIN";

	private var _guid:String;
	private var _region:Region;
	
	public function get guid():String { return _guid; } 
	
	public function get region():Region  { return _region; }
	
	public function RegionEvent( $type:String, $guid:String, $region:Region = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
		_region = $region;
	}
	
	public override function clone():Event
	{
		return new RegionEvent(type, _guid, _region, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("RegionEvent", "bubbles", "cancelable") + " regionId: " + _guid;
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

	static public function dispatch( $event:RegionEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
	
}
}
