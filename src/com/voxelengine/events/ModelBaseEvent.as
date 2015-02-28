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
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelBaseEvent extends Event
{
	//// tells the manager to load this model
	static public const REQUEST:String						= "REQUEST";
	//// tells the manager to load this type of model
	static public const REQUEST_TYPE:String					= "REQUEST_TYPE";
	//// the response to a REQUEST or REQUEST_TYPE is one or mode ADDED messages
	//// tells us the manager has add this from persistance
	static public const ADDED:String						= "ADDED";
	static public const REQUEST_FAILED:String				= "REQUEST_FAILED";
	
	// data or meta data about this region has changed
	static public const CHANGED:String						= "CHANGED";
	static public const SAVE:String							= "SAVE";
	static public const UPDATE:String						= "UPDATE";
	static public const SAVE_FAILED:String					= "SAVE_FAILED";
	
	
	public function ModelBaseEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
}
}
