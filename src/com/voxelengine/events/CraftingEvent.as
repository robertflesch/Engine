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

public class CraftingEvent extends ModelBaseEvent
{
	private var _name:String;
    public function get name():String { return _name; }
	private var _recipe:Recipe;
    public function get recipe():Recipe { return _recipe; }

	public function CraftingEvent( $type:String, $name:String, $recipe:Recipe ) {
		super( $type, 0 );
		_recipe = $recipe;
		_name = $name;
	}
	
	public override function clone():Event {
		return new CraftingEvent(type, _name, _recipe );
	}
   
	public override function toString():String {
		return formatToString("CraftingEvent", "bubbles", "cancelable") + " name: " + _name + " recipe: " + _recipe.toString();
	}

	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistence messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

    static public function create( $type:String, $name:String, $recipe:Recipe ) : Boolean {
        return _eventDispatcher.dispatchEvent( new  CraftingEvent( $type, $name, $recipe ) );
    }
	///////////////// Event handler interface /////////////////////////////
	
}
}
