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

import playerio.PlayerIOError;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class GUIEvent extends Event
{
	static public const TOOLBAR_HIDE:String		= "TOOLBAR_HIDE";
	static public const TOOLBAR_SHOW:String		= "TOOLBAR_SHOW";
	
	private var _error:PlayerIOError;
	public function get error():PlayerIOError { return _error; }
	
	public function GUIEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
	
	public override function clone():Event
	{
		return new GUIEvent(type, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("GUIEvent", "bubbles", "cancelable");
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

	static public function dispatch( $event:GUIEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
		
	}
}
