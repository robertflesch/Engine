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

import com.voxelengine.worldmodel.models.ModelData;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelDataEvent extends ModelBaseEvent
{
	private var _vmd:ModelData;
	private var _guid:String;
	private var _fromTables:Boolean;

	public function get vmd():ModelData { return _vmd; }
	public function get guid():String  { return _guid; }
	public function get fromTables():Boolean  { return _fromTables; }
	
	public function ModelDataEvent( $type:String, $series:int, $guid:String, $vmd:ModelData, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_vmd = $vmd;
		_guid = $guid;
		_fromTables = $fromTable;
	}
	
	public override function clone():Event {
		return new ModelDataEvent(type, series, _guid, _vmd, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString("ModelDataEvent", "series", "guid" );
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

	static public function dispatch( $event:ModelDataEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
