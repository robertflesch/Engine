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
	public class RegionPersistanceEvent extends Event
	{
		static public const REGION_CREATE_SUCCESS:String		= "REGION_CREATE_SUCCESS";
		static public const REGION_CREATE_FAILURE:String		= "REGION_CREATE_FAILURE";
		
		// Not handled anywhere
		static public const REGION_SAVE_SUCCESS:String			= "REGION_SAVE_SUCCESS";
		static public const REGION_SAVE_FAILURE:String			= "REGION_SAVE_FAILURE";
		
		private var _guid:String;
		
		public function RegionPersistanceEvent( $type:String, $guid:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new RegionPersistanceEvent(type, _guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("PersistanceEvent", "bubbles", "cancelable") + "  guid: " + _guid;
		}
		
	}
}
