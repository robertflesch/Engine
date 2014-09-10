/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import adobe.utils.ProductManager;
	import flash.events.Event;
	import playerio.PlayerIOError;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class LoginEvent extends Event
	{
		static public const LOGIN_SUCCESS:String		= "LOGIN_SUCCESS";
		static public const LOGIN_FAILURE:String		= "LOGIN_FAILURE";
		static public const SANDBOX_SUCCESS:String		= "SANDBOX_SUCCESS";
		
		static public const JOIN_ROOM_SUCCESS:String		= "JOIN_ROOM_SUCCESS";
		static public const JOIN_ROOM_FAILURE:String		= "JOIN_ROOM_FAILURE";

		private var _error:PlayerIOError;
		private var _guid:String;
		public function get error():PlayerIOError { return _error; }
		
		public function get guid():String { return _guid; }
		
		public function LoginEvent( $type:String, error:PlayerIOError, $guid:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new LoginEvent(type, error, guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("LoginEvent", "bubbles", "cancelable") + _error ? _error.message : "" + "  guid: " + guid;
		}
		
	}
}
