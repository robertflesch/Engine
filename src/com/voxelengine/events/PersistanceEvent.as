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
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class PersistanceEvent extends Event
{
	static public const LOAD_REQUEST:String  	= "LOAD_REQUEST";
	static public const LOAD_REQUEST_TYPE:String = "LOAD_REQUEST_TYPE";
	static public const LOAD_SUCCEED:String  	= "LOAD_SUCCEED";
	static public const LOAD_FAILED:String  	= "LOAD_FAILED";
	static public const LOAD_NOT_FOUND:String 	= "LOAD_NOT_FOUND";
	
	static public const SAVE_REQUEST:String  	= "SAVE_REQUEST";
	static public const CREATE_SUCCEED:String	= "CREATE_SUCCEED";
	static public const SAVE_SUCCEED:String  	= "SAVE_SUCCEED";
	static public const CREATE_FAILED:String	= "CREATE_FAILED";
	static public const SAVE_FAILED:String  	= "SAVE_FAILED";

	private var _guid:String;
	private var _dbo:DatabaseObject;
	private var _data:*;
	private var _table:*;
	private var _format:String;
	
	public function get guid():String  { return _guid; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function get data():* { return _data; }
	public function get table():String  { return _table; }
	public function get format():String { return _format;}

	public function PersistanceEvent( $type:String, $table:String, $guid:String, $dbo:DatabaseObject = null, $data:* = null, $format:String = URLLoaderDataFormat.TEXT, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
		_table = $table
		_dbo = $dbo;
		_data = $data;
		_format = $format;
	}
	
	public override function clone():Event
	{
		return new PersistanceEvent(type, table, guid, dbo, data, format, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("PersistanceEvent", "table", "guid", "dbo", "data", "format" );
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

	static public function dispatch( $event:PersistanceEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}