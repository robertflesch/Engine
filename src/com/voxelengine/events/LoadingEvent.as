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
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class LoadingEvent extends Event
	{
		static public const LOAD_COMPLETE:String			= "LOAD_COMPLETE";
		static public const PLAYER_LOAD_COMPLETE:String		= "PLAYER_LOAD_COMPLETE";
		static public const MODEL_LOAD_COMPLETE:String		= "MODEL_LOAD_COMPLETE";
		static public const CRITICAL_MODEL_LOADED:String	= "CRITICAL_MODEL_LOADED";
		static public const MODEL_LOAD_FAILURE:String		= "MODEL_LOAD_FAILURE";
		
		static public const SPLASH_LOAD_COMPLETE:String		= "SPLASH_LOAD_COMPLETE";
		static public const LOAD_TYPES_COMPLETE:String		= "LOAD_TYPES_COMPLETE";
		
		static public const ANIMATION_LOAD_COMPLETE:String	= "ANIMATION_LOAD_COMPLETE";

		private var _guid:String = "";
		public function LoadingEvent( $type:String, $guid:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new LoadingEvent(type, _guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("LoadingEvent", "guid", "bubbles", "cancelable");
		}
		
		public function get guid():String 
		{
			return _guid;
		}
		
	}
}
