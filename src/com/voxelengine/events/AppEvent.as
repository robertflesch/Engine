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

import com.voxelengine.worldmodel.weapons.Ammo;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class AppEvent extends Event
{
	static public const APP_DEACTIVATE:String					= "APP_DEACTIVATE";
	static public const APP_ACTIVATE:String						= "APP_ACTIVATE";
	static public const INTERNAL_ENTER_FRAME:String				= "INTERNAL_ENTER_FRAME";
	
	public function AppEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
	
	public override function toString():String {
		return formatToString( "AppEvent", "type" );
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

	static public function dispatch( $event:AppEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
