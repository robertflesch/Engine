/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.animation.SoundPersistance;
import flash.events.Event
import flash.events.EventDispatcher

import com.voxelengine.worldmodel.animation.AnimationSound
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class SoundEvent extends ModelBaseEvent
{
	private var _guid:String // animation guid or fileName
	private var _snd:SoundPersistance
	private var _fromTables:Boolean

	public function get guid():String  { return _guid }
	public function get fromTables():Boolean  { return _fromTables }
	public function get snd():SoundPersistance  { return _snd }
	
	public function SoundEvent( $type:String, $series:int, $guid:String, $snd:SoundPersistance = null, $fromTables:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable )
		_guid = $guid
		_fromTables = $fromTables
		_snd = $snd
	}
	
	public override function clone():Event {
		return new SoundEvent(type, series, _guid, _snd, _fromTables, bubbles, cancelable)
	}
   
	public override function toString():String {
		return formatToString("SoundEvent", "series", "guid", "snd", "fromTables" )
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher()

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference )
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture )
	}

	static public function dispatch( $event:SoundEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event )
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
