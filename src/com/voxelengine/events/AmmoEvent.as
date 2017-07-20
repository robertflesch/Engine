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
public class AmmoEvent extends ModelBaseEvent
{
	static public const AMMO_SELECTED:String	= "AMMO_SELECTED";

	private var _guid:String;
	private var _ammo:Ammo;
	private var _fromTable:Boolean;
	public function get guid():String { return _guid; }
	public function get ammo():Ammo  { return _ammo; }
	public function get fromTable():Boolean  { return _fromTable; }
	
	public function AmmoEvent( $type:String, $series:int, $guid:String, $ammo:Ammo, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_fromTable = $fromTable;
		_guid = $guid;
		_ammo = $ammo;
	}
	
	public override function clone():Event {
		return new AmmoEvent(type, series, _guid, _ammo, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString( "AmmoEvent", "series", "guid", "ammo", "vmd" );
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

	static public function dispatch( $event:AmmoEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	static public function create( $type:String, $series:int, $guid:String, $ammo:Ammo, $fromTable:Boolean = true) : Boolean {
		return _eventDispatcher.dispatchEvent( new AmmoEvent( $type, $series, $guid, $ammo, $fromTable ) );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
