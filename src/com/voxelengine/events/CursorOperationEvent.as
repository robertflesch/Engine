/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.inventory.ObjectModel;
import flash.events.Event;
import flash.events.EventDispatcher;

public class CursorOperationEvent extends Event
{
	static public	const NONE:String 			= "NONE";
	static public	const INSERT_OXEL:String 	= "INSERT_OXEL";
	static public	const INSERT_MODEL:String 	= "INSERT_MODEL";
	static public 	const DELETE_OXEL:String 	= "DELETE_OXEL";
	//static public 	const DELETE_MODEL:String 	= "DELETE_MODEL";
	static public 	const ACTIVATE:String 		= "ACTIVATE";

	private var _oxelType:int;
	private var _om:ObjectModel;
	
	public function get oxelType():int { return _oxelType; }
	public function get om():ObjectModel { return _om; }
	
	public function CursorOperationEvent( $type:String, $oxelType:int = 0, $om:ObjectModel = null, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
		_oxelType	= $oxelType;
		_om 		= $om;
	}
	
	public override function clone():Event {
		return new CursorOperationEvent(type, _oxelType, _om, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString("CursorEvent", "type", "_oxelType", "_om", "bubbles", "cancelable");
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

	static public function dispatch( $event:CursorOperationEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	static public function create( $type:String, $oxelType:int = 0, $om:ObjectModel = null ) : Boolean {
		return _eventDispatcher.dispatchEvent( new CursorOperationEvent( $type, $oxelType, $om ) );
	}

	
	
	///////////////// Event handler interface /////////////////////////////
}
}
