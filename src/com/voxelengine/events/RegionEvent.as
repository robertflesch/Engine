/*==============================================================================
  Copyright 2011-2014 Robert Flesch
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
	public class RegionEvent extends Event
	{
		// Used to request public and private regions from persistance
		static public const REQUEST_PRIVATE:String					= "REQUEST_PRIVATE";
		static public const REQUEST_PUBLIC:String					= "REQUEST_PUBLIC";
		
		// tells the region manager to load this region
		static public const REGION_LOAD:String						= "REGION_LOAD";
		// dispatched at the begining of a region load
		static public const REGION_LOAD_BEGUN:String				= "REGION_LOAD_BEGUN";
		// dispatched when a region is unloaded
		static public const REGION_UNLOAD:String					= "REGION_UNLOAD";
		// dispatched when a region is modified in the UI
		static public const REGION_MODIFIED:String					= "REGION_MODIFIED";

		private var _guid:String;
		
		public function get guid():String { return _guid; } 
		
		public function RegionEvent( $type:String, $guid:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_guid = $guid;
		}
		
		public override function clone():Event
		{
			return new RegionEvent(type, _guid, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("RegionEvent", "bubbles", "cancelable") + " regionId: " + _guid;
		}
		
	}
}
