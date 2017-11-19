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
import flash.events.EventDispatcher;

import com.voxelengine.worldmodel.TypeInfo;

public class CraftingItemEvent extends Event
{
	static public const BONUS_DROPPED:String				= "BONUS_DROPPED";
	static public const BONUS_REMOVED:String				= "BONUS_REMOVED";
	static public const MATERIAL_DROPPED:String				= "MATERIAL_DROPPED";
	static public const MATERIAL_REMOVED:String				= "MATERIAL_REMOVED";
	static public const STATS_UPDATED:String				= "STATS_UPDATED";
    static public const REQUIREMENTS_MET:String				= "REQUIREMENTS_MET";

	private var _typeInfo:TypeInfo;
    public function get typeInfo():TypeInfo { return _typeInfo; }
    private var _data:*;
    public function get data():* { return _data; }

	public function CraftingItemEvent( $type:String, $typeInfo:TypeInfo, $data:* ) {
		super( $type );
		_typeInfo = $typeInfo;
		_data = $data;
	}
	
	public override function clone():Event { return new CraftingItemEvent(type, _typeInfo, _data); }
	public override function toString():String { return formatToString("CraftingMaterialEvent", "typeInfo", "data" ); }
	
	///////////////// Event handler interface /////////////////////////////
	// Used to distribute all persistence messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function create( $type:String, $typeInfo:TypeInfo, $data:* = null ) : Boolean {
		return _eventDispatcher.dispatchEvent( new CraftingItemEvent( $type, $typeInfo, $data ) );
	}
	///////////////// Event handler interface /////////////////////////////
}
}
