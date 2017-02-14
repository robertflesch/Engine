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

import com.voxelengine.worldmodel.weapons.Ammo;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class GunEvent extends Event
{
	static public const AMMO_ADDED:String						= "AMMO_ADDED";
	static public const AMMO_LOAD_COMPLETE:String				= "AMMO_LOAD_COMPLETE";
	//static public const AMMO_EXHUSTED:String					= "AMMO_EXHUSTED";
	//static public const AMMO_REMOVED:String						= "AMMO_REMOVED";
	private var _guid:String;
	private var _data1:*;
	private var _data2:*;
	public function get data1():* { return _data1; }
	public function get data2():* { return _data2; }
	public function GunEvent( $type:String, $guid:String, $data1:* = null, $data2:* = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
		_data1 = $data1;
		_data2 = $data2;
	}
	
	public override function clone():Event {
		return new GunEvent(type, _guid, _data1, _data2, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString( "GunEvent", "data1", "data2" );
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:GunEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	
	///////////////// Event handler interface /////////////////////////////
}
}
