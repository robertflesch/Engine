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
 * 
 */
public class LoadingEvent extends Event
{
	static public const LOAD_COMPLETE:String			= "LOAD_COMPLETE";
	static public const PLAYER_LOAD_COMPLETE:String		= "PLAYER_LOAD_COMPLETE";
// MOVE TO MODEL EVENT		
	static public const TEMPLATE_MODEL_COMPLETE:String	= "TEMPLATE_MODEL_COMPLETE";
	
	static public const LOAD_TYPES_COMPLETE:String		= "LOAD_TYPES_COMPLETE";
	static public const LOAD_CONFIG_COMPLETE:String		= "LOAD_CONFIG_COMPLETE";
	
	private var _modelGuid:String = "";
	public function get modelGuid():String { return _modelGuid; }

	public override function clone():Event { return new LoadingEvent(type, _modelGuid, bubbles, cancelable); }
	public override function toString():String { return formatToString("LoadingEvent", "modelGuid"); }
	
	public function LoadingEvent( $type:String, $modelGuid:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
		_modelGuid = $modelGuid;
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

	static public function dispatch( $event:LoadingEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
