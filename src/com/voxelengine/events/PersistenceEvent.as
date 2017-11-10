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
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class PersistenceEvent extends Event
{
	static public const LOAD_REQUEST:String  	= "LOAD_REQUEST";
	static public const LOAD_REQUEST_TYPE:String = "LOAD_REQUEST_TYPE";
	static public const LOAD_SUCCEED:String  	= "LOAD_SUCCEED";
	static public const LOAD_FAILED:String  	= "LOAD_FAILED";
	static public const LOAD_NOT_FOUND:String 	= "LOAD_NOT_FOUND";

	static public const GENERATE_SUCCEED:String = "GENERATE_SUCCEED";
    static public const CLONE_SUCCEED:String 	= "CLONE_SUCCEED";

	static public const SAVE_REQUEST:String  	= "SAVE_REQUEST";
	static public const CREATE_SUCCEED:String	= "CREATE_SUCCEED";
	static public const SAVE_SUCCEED:String  	= "SAVE_SUCCEED";
	static public const CREATE_FAILED:String	= "CREATE_FAILED";
	static public const SAVE_FAILED:String  	= "SAVE_FAILED";

	static public const DELETE_REQUEST:String  	= "DELETE_REQUEST";
	static public const DELETE_SUCCEED:String  	= "DELETE_SUCCEED";
	static public const DELETE_FAILED:String  	= "DELETE_FAILED";

	private var _guid:String;
	private var _dbo:DatabaseObject;
	private var _data:*;
	private var _table:String;
	private var _other:String;
	private var _format:String; // only used in local file access PersistLocal
	private var _series:int;
	
	public function get series():int { return _series; }
	public function set series(value:int):void { _series = value; }
	public function get guid():String  { return _guid; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function get data():* { return _data; }
	public function get other():String  { return _other; }
	public function get table():String  { return _table; }
	public function get format():String { return _format;}

	public function PersistenceEvent($type:String, $series:int, $table:String, $guid:String, $dbo:DatabaseObject = null, $data:* = null, $format:String = URLLoaderDataFormat.TEXT, $other:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_series = $series;
		_guid = $guid;
		_table = $table;
		_dbo = $dbo;
		_data = $data;
		_format = $format;
		_other = $other;
	}
	
	public override function clone():Event
	{
		return new PersistenceEvent(type, series, table, guid, dbo, data, format, other, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("PersistenceEvent", "type", "table", "guid", "dbo", "data", "series" );
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistence messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:PersistenceEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	static public function create( $type:String, $series:int, $table:String, $guid:String, $dbo:DatabaseObject = null, $data:* = null, $format:String = URLLoaderDataFormat.TEXT, $other:String = "" ):Boolean {
		return _eventDispatcher.dispatchEvent( new PersistenceEvent( $type, $series, $table, $guid, $dbo, $data, $format, $other ) );
	}

	///////////////// Event handler interface /////////////////////////////
}
}