/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import com.voxelengine.worldmodel.crafting.Recipe;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class CraftingEvent extends Event
	{
		static public const RECIPE_LOAD_PUBLIC:String			= "RECIPE_LOAD_PUBLIC";
		static public const RECIPE_LOADED:String				= "RECIPE_LOADED";
		
		private var _name:String;
		private var _recipe:Recipe;
		
		public function CraftingEvent( $type:String, $name:String, $recipe:Recipe, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_recipe = $recipe;
			_name = $name;
		}
		
		public override function clone():Event
		{
			return new CraftingEvent(type, _name, _recipe, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("CraftingEvent", "bubbles", "cancelable") + " name: " + _name + " recipe: " + _recipe.toString();
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function get recipe():Recipe 
		{
			return _recipe;
		}
		
		
	}
}
