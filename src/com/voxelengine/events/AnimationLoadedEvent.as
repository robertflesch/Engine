/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import com.voxelengine.worldmodel.animation.Animation;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class AnimationLoadedEvent extends Event
	{
		static public const ANIMATION_CREATED:String				= "ANIMATION_CREATED";
		//static public const ANIMATION_LOADED:String					= "ANIMATION_LOADED";
		
		private var _anim:Animation;
		
		public function get anim():Animation { return _anim; } 
		
		public function AnimationLoadedEvent( $type:String, $anim:Animation )
		{
			super( $type, false, false );
			_anim = $anim;
		}
		
		public override function clone():Event
		{
			return new AnimationLoadedEvent(type, _anim);
		}
	   
		public override function toString():String
		{
			return formatToString("AnimationLoadedEvent", "bubbles", "cancelable") + " animId: " + _anim.guid;
		}
		
	}
}
