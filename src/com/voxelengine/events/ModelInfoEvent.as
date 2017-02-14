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
import flash.utils.ByteArray;
import flash.events.EventDispatcher;

import com.voxelengine.worldmodel.models.ModelInfo;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelInfoEvent extends ModelBaseEvent
{
	static public const DELETE_RECURSIVE:String					= "DELETE_RECURSIVE";
	
	private var _vmi:ModelInfo;
	private var _modelGuid:String;
	private var _fromTables:Boolean;

	public function get vmi():ModelInfo { return _vmi; }
	public function get modelGuid():String { return _modelGuid; }
	public function get fromTables():Boolean  { return _fromTables; }
	
	public function ModelInfoEvent( $type:String, $series:int, $guid:String, $vmi:ModelInfo, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_vmi = $vmi;
		_modelGuid = $guid;
		_fromTables = $fromTable;
	}
	
	public override function toString():String { return formatToString("ModelInfoEvent", "series", "modelGuid", "vmi", "fromTables" ); }
	public override function clone():Event { return new ModelInfoEvent(type, series, _modelGuid, _vmi, _fromTables, bubbles, cancelable); }
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function hasEventListener( $type:String ) : Boolean {
		return _eventDispatcher.hasEventListener( $type );
	}
	
	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:ModelInfoEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	static public  function create( $type:String, $series:int, $guid:String, $vmi:ModelInfo, $fromTable:Boolean = true ):Boolean {
		return ModelInfoEvent.dispatch( new ModelInfoEvent( $type, $series, $guid, $vmi, $fromTable ) );
	}



	///////////////// Event handler interface /////////////////////////////
}
}
