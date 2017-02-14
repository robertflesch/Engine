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
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class VVWindowEvent extends Event
	{
		static public const WINDOW_CLOSING:String	= "WINDOW_CLOSING";

		private var _windowTitle:String
		
		public function VVWindowEvent( $type:String, $windowTitle:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_windowTitle = $windowTitle;
		}
		
		public override function clone():Event
		{
			return new VVWindowEvent(type, _windowTitle, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("VVWindowEvent", "bubbles", "cancelable") + " windowTitle: " + _windowTitle;
		}
		
		public function get windowTitle():String 
		{
			return _windowTitle;
		}
	}
}
