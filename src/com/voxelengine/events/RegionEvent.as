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

import com.voxelengine.worldmodel.Region;
/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class RegionEvent extends ModelBaseEvent
{
	// INHERITS static public const from ModelBaseEvent
	//static public const REQUEST:String						= "REQUEST";
	//static public const REQUEST_TYPE:String					= "REQUEST_TYPE";
	//static public const ADDED:String							= "ADDED";
	//static public const REQUEST_FAILED:String					= "REQUEST_FAILED";
	//static public const SAVE:String							= "SAVE";
	
	// These are the region specific events
	// dispatched when a region is unloaded
	static public const UNLOAD:String						= "UNLOAD";
	// tells the region manager to load this region
	static public const LOAD:String							= "LOAD";
	// dispatched after jobs for all process have been added
	static public const LOAD_BEGUN:String					= "LOAD_BEGUN";
	// tells the region manager this region had finished loading
	static public const LOAD_COMPLETE:String				= "LOAD_COMPLETE";
	
	// Used by the sandbox list and config manager to request a join of a server region
	static public const JOIN:String							= "JOIN";

	private var _guid:String;
	private var _region:Region;
	
	public function get guid():String { return _guid; } 
	
	public function get region():Region  { return _region; }
	
	public function RegionEvent( $type:String, $series:int, $guid:String, $region:Region = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_guid = $guid;
		_region = $region;
	}
	
	public override function clone():Event
	{
		return new RegionEvent(type, series, _guid, _region, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("RegionEvent", "series", "guid", "region");
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

	static public function create( $type:String, $series:int, $guid:String, $region:Region = null ) : Boolean {
		return _eventDispatcher.dispatchEvent( new RegionEvent( $type, $series, $guid, $region ) );
	}

	///////////////// Event handler interface /////////////////////////////
	
}
}
