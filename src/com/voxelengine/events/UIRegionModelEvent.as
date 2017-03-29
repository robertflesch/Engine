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
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class UIRegionModelEvent extends Event
{
	static public const SELECTED_MODEL_CHANGED:String	= "SELECTED_MODEL_CHANGED";
	static public const SELECTED_MODEL_REMOVED:String	= "SELECTED_MODEL_REMOVED";
	
	private var _voxelModel:VoxelModel;
	private var _parentVM:VoxelModel;
	private var _level:int;
	public function get voxelModel():VoxelModel 	{ return _voxelModel; }
	public function get parentVM():VoxelModel 		{ return _parentVM; }
	public function get level():int 				{ return _level; }
	
	public function UIRegionModelEvent( $type:String, $vm:VoxelModel, $parentVM:VoxelModel, $level:int ) {
		super( $type );
		_level = $level;
		_voxelModel = $vm;
		_parentVM = $parentVM;
	}
	
	public override function clone():Event {
		return new UIRegionModelEvent(type, _voxelModel, _parentVM, _level );
	}
   
	public override function toString():String{
		return "UIRegionModelEvent instanceGuid: " + _voxelModel.instanceInfo.instanceGuid + "  parentInfo: " + _parentVM ? _parentVM.instanceInfo.modelGuid : "No parent";
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

//	static public function dispatch( $event:UIRegionModelEvent ) : Boolean {
//		return _eventDispatcher.dispatchEvent( $event );
//	}

	static public function create( $type:String, $vm:VoxelModel, $parentVM:VoxelModel, $level:int ) : Boolean {
		return _eventDispatcher.dispatchEvent( new UIRegionModelEvent( $type, $vm, $parentVM, $level ) );
	}

		///////////////// Event handler interface /////////////////////////////
	
}
}
