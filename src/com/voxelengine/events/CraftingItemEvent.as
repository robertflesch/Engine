/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.TypeInfo;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.events.EventDispatcher;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class CraftingItemEvent extends Event
{
	static public const BONUS_DROPPED:String				= "BONUS_DROPPED";
	static public const BONUS_REMOVED:String				= "BONUS_REMOVED";
	static public const MATERIAL_DROPPED:String				= "MATERIAL_DROPPED";
	static public const MATERIAL_REMOVED:String				= "MATERIAL_REMOVED";
	static public const STATS_UPDATED:String				= "STATS_UPDATED";
	
	
	private var _typeInfo:TypeInfo;
	
	public function CraftingItemEvent( $type:String, $typeInfo:TypeInfo, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_typeInfo = $typeInfo
	}
	
	public override function clone():Event
	{
		return new CraftingItemEvent(type, _typeInfo, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("CraftingMaterialEvent", "bubbles", "cancelable") + " _typeInfo: " + _typeInfo.toString();
	}
	
	public function get typeInfo():TypeInfo 
	{
		return _typeInfo;
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

	static public function dispatch( $event:CraftingItemEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
