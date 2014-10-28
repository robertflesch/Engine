/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import flash.events.Event;
	import playerio.PlayerIOError;
	
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
		
	}
}
