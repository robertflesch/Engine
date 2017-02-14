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

import com.voxelengine.Log;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class WindowSplashEvent extends Event
{
	static public const CREATE:String  	= "CREATE";
	static public const DESTORY:String	= "DESTORY";
	static public const ANNIHILATE:String	= "ANNIHILATE"; // This closes regardless of online state
	static public const SPLASH_LOAD_COMPLETE:String	= "SPLASH_LOAD_COMPLETE";
	

	public function WindowSplashEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
	}
	
	public override function clone():Event { return new WindowSplashEvent(type, bubbles, cancelable); }
   
	public override function toString():String { return formatToString("WindowSplashEvent: " + type ); }
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:WindowSplashEvent ) : Boolean {
		//Log.out( $event.toString(), Log.WARN );
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}