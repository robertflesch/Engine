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
	public class RoomEvent extends Event
	{
		static public const ROOM_JOIN_SUCCESS:String		= "ROOM_JOIN_SUCCESS";
		static public const ROOM_JOIN_FAILURE:String		= "ROOM_JOIN_FAILURE";
		static public const ROOM_DISCONNECT:String			= "ROOM_DISCONNECT";

		private var _error:PlayerIOError;
		private var _guid:String;
		public function get error():PlayerIOError { return _error; }
		
		public function get guid():String { return _guid; }
		
		public function RoomEvent( $type:String, error:PlayerIOError, $guid:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new RoomEvent(type, error, guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("RoomEvent", "bubbles", "cancelable") + _error ? _error.message : "" + "  guid: " + guid;
		}
		
	}
}
