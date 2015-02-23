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
public class PersistanceEvent extends Event
{
	static public const LOAD_REQUEST:String  	= "LOAD_REQUEST";
	static public const LOAD_REQUEST_TYPE:String = "LOAD_REQUEST_TYPE";
	static public const LOAD_REQUEST_ALL:String = "LOAD_REQUEST_ALL";
	static public const LOAD_SUCCEED:String  	= "LOAD_SUCCEED";
	static public const LOAD_FAILED:String  	= "LOAD_FAILED";
	static public const LOAD_NOT_FOUND:String 	= "LOAD_NOT_FOUND";
	
	static public const SAVE_REQUEST:String  	= "SAVE_REQUEST";
	static public const CREATE_SUCCEED:String	= "CREATE_SUCCEED";
	static public const SAVE_SUCCEED:String  	= "SAVE_SUCCEED";
	static public const CREATE_FAILED:String	= "CREATE_FAILED";
	static public const SAVE_FAILED:String  	= "SAVE_FAILED";

	public function PersistanceEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
}
}