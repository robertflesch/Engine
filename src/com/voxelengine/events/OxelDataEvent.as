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
import flash.utils.ByteArray;
import flash.events.EventDispatcher;

import com.voxelengine.worldmodel.models.OxelPersistance;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class OxelDataEvent extends ModelBaseEvent
{
	static public const OXEL_READY:String					= "OXEL_READY"
	
	private var _od:OxelPersistance;
	private var _modelGuid:String;
	private var _fromTables:Boolean;

	public function get oxelData():OxelPersistance { return _od; }
	public function get modelGuid():String  { return _modelGuid; }
	public function get fromTables():Boolean  { return _fromTables; }
	
	public function OxelDataEvent( $type:String, $series:int, $guid:String, $vmd:OxelPersistance, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_od = $vmd;
		_modelGuid = $guid;
		_fromTables = $fromTable;
	}
	
	public override function clone():Event {
		return new OxelDataEvent(type, series, _modelGuid, _od, _fromTables, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString( "OxelDataEvent", "series", "modelGuid", "oxelData", "fromTables" );
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

	static public function dispatch( $event:OxelDataEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
