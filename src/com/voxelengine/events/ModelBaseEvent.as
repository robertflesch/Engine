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

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelBaseEvent extends Event
{
	static private var _seriesCounter:int;
	private var _series:int;
	public function get series():int { return _series; }
	public function set series(value:int):void { _series = value; }
	
	static public const USE_FILE_SYSTEM:Boolean = false;
	static public const USE_PERSISTANCE:Boolean = true;
	
	//// tells the manager to load this model
	static public const REQUEST:String						= "REQUEST";
	//// tells the manager to load this type of model
	static public const REQUEST_TYPE:String					= "REQUEST_TYPE";
	//// the response to a REQUEST or REQUEST_TYPE is one or mode ADDED messages
	//// tells us the manager has add this from persistance
	static public const ADDED:String						= "ADDED";
	static public const RESULT:String						= "RESULT";
	static public const RESULT_COMPLETE:String				= "RESULT_COMPLETE";
	static public const REQUEST_FAILED:String				= "REQUEST_FAILED";
	static public const IMPORT_COMPLETE:String				= "IMPORT_COMPLETE";
	static public const CLONE:String						= "CLONE";

	// New sequence to see if data exists already, used by generation system
	static public const EXISTS_REQUEST:String				= "EXISTS_REQUEST";
	static public const EXISTS:String						= "EXISTS";
	static public const EXISTS_FAILED:String				= "EXISTS_FAILED";
	static public const EXISTS_ERROR:String					= "EXISTS_ERROR";

	
	// data or meta data about this object has changed
	static public const CREATED:String						= "CREATED";
	static public const CHANGED:String						= "CHANGED";
	static public const SAVE:String							= "SAVE";
	static public const UPDATE:String						= "UPDATE";
	static public const UPDATE_GUID:String					= "UPDATE_GUID";

	static public const DELETE:String						= "DELETE";

	static public const GENERATION:String					= "GENERATION";
	
	public function ModelBaseEvent( $type:String, $series:int, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		if ( ( $type == REQUEST || $type == REQUEST_TYPE ) && 0 == $series )
			_series = _seriesCounter++; // start of a new series, inc counter
		else
			_series = $series;
			
		super( $type, $bubbles, $cancellable );
	}

	static public function get seriesCounter():int {
		return _seriesCounter;
	}
}
}
