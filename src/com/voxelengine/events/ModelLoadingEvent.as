/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.models.types.VoxelModel;
import flash.events.Event;
import flash.events.EventDispatcher;

public class ModelLoadingEvent extends Event
{
	static public const MODEL_LOAD_COMPLETE:String		= "MODEL_LOAD_COMPLETE";
	static public const MODEL_LOAD_FAILURE:String		= "MODEL_LOAD_FAILURE";
	static public const CHILD_LOADING_COMPLETE:String	= "CHILD_LOADING_COMPLETE";
	static public const CRITICAL_MODEL_LOADED:String	= "CRITICAL_MODEL_LOADED";
	
	private var _vm:VoxelModel;
	private var _data:ObjectHierarchyData;
	
	public function get vm():VoxelModel { return _vm; }
	public function get data():ObjectHierarchyData { return _data; }

	public function ModelLoadingEvent($type:String, $data:ObjectHierarchyData, $vm:VoxelModel = null ) {
		super( $type );
		_data = $data;
		_vm = $vm;
	}
	
	public override function clone():Event {
		return new ModelLoadingEvent(type, _data, _vm);
	}
   
	public override function toString():String {
		return formatToString("ModelLoadingEvent", "data", "vm" );
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

	static public function create( $type:String, $data:ObjectHierarchyData, $vm:VoxelModel = null ) : Boolean {
		return _eventDispatcher.dispatchEvent( new ModelLoadingEvent( $type, $data, $vm ) );
	}
	///////////////// Event handler interface /////////////////////////////
	
}
}
