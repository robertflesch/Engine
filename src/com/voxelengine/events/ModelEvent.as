/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events {
import com.voxelengine.worldmodel.models.types.VoxelModel;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.events.EventDispatcher;

public class ModelEvent extends Event {
	static public const MOVED:String					= "MOVED";
	static public const DETACH:String					= "DETACH";
	static public const INFO_LOADED:String				= "INFO_LOADED";
	static public const TAKE_CONTROL:String 			= "TAKE_CONTROL";
	static public const RELEASE_CONTROL:String 			= "RELEASE_CONTROL";
	static public const CHILD_MODEL_ADDED:String		= "CHILD_MODEL_ADDED";
	static public const PARENT_MODEL_ADDED:String		= "PARENT_MODEL_ADDED";
	static public const DYNAMIC_MODEL_ADDED:String		= "DYNAMIC_MODEL_ADDED";
	static public const AVATAR_MODEL_ADDED:String		= "AVATAR_MODEL_ADDED";
	static public const PARENT_MODEL_REMOVED:String		= "PARENT_MODEL_REMOVED";
	static public const CRITICAL_MODEL_DETECTED:String	= "CRITICAL_MODEL_DETECTED";
    static public const CLONE_COMPLETE:String			= "CLONE_COMPLETE";

	private var _parentInstanceGuid:String;
	public function get parentInstanceGuid():String { return _parentInstanceGuid; }
	
	private var _rotation:Vector3D;
	private var _position:Vector3D;
	private var _instanceGuid:String;
	private var _vm:VoxelModel;
	
	public function get rotation():Vector3D { return _rotation; }
	public function get position():Vector3D { return _position; }
	public function get instanceGuid():String { return _instanceGuid; }
	public function get vm():VoxelModel { return _vm }
	
	public function ModelEvent( $type:String, $instanceGuid:String, $position:Vector3D = null, $rotation:Vector3D = null, $parentInstanceGuid:String = "", $vm:VoxelModel = null, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable );
		_instanceGuid = $instanceGuid;
		_rotation = $rotation;
		_position = $position;
		_parentInstanceGuid = $parentInstanceGuid;
		_vm = $vm;
	}
	
	public override function clone():Event {
		return new ModelEvent(type, _instanceGuid, _rotation, _position, _parentInstanceGuid, _vm, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString("ModelEvent", "instanceGuid", "rotation", "position", "parentInstanceGuid", "vm" );
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

    static public function create( $type:String, $instanceGuid:String, $position:Vector3D = null, $rotation:Vector3D = null, $parentInstanceGuid:String = "", $vm:VoxelModel = null ) : Boolean {
        return _eventDispatcher.dispatchEvent( new ModelEvent( $type, $instanceGuid, $position, $rotation, $parentInstanceGuid, $vm ) );
    }

	///////////////// Event handler interface /////////////////////////////
	
}
}
