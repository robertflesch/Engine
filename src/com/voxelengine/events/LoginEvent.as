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


/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class LoginEvent extends Event
{
	static public const LOGIN_SUCCESS:String			= "LOGIN_SUCCESS";
	static public const LOGIN_FAILURE:String			= "LOGIN_FAILURE";
	static public const LOGIN_FAILURE_PASSWORD:String	= "LOGIN_FAILURE_PASSWORD";
	static public const LOGIN_FAILURE_EMAIL:String		= "LOGIN_FAILURE_EMAIL";
	
	static public const PASSWORD_RECOVERY_SUCCESS:String			= "PASSWORD_RECOVERY_SUCCESS";
	static public const PASSWORD_RECOVERY_FAILURE:String			= "PASSWORD_RECOVERY_FAILURE";
	
	private var _guid:String;
	
	public function get guid():String { return _guid; }
	
	public function LoginEvent( $type:String, $guid:String = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_guid = $guid;
	}
	
	public override function clone():Event
	{
		return new LoginEvent(type, guid, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("LoginEvent", "bubbles", "cancelable") + "  guid: " + guid;
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

	static public function dispatch( $event:LoginEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	///////////////// Event handler interface /////////////////////////////
}	
}
