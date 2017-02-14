/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.crafting.Recipe;
import flash.events.Event;
import flash.events.EventDispatcher;

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
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:CraftingEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
}
}
