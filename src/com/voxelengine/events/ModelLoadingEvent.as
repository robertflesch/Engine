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

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelLoadingEvent extends Event
{
	static public const MODEL_LOAD_COMPLETE:String		= "MODEL_LOAD_COMPLETE";
	static public const MODEL_LOAD_FAILURE:String		= "MODEL_LOAD_FAILURE";
	static public const CHILD_LOADING_COMPLETE:String	= "CHILD_LOADING_COMPLETE";
	static public const CRITICAL_MODEL_LOADED:String	= "CRITICAL_MODEL_LOADED";
	
	private var _parentModelGuid:String;
	private var _vm:VoxelModel;
	private var _modelGuid:String;
	
	public function get modelGuid():String { return _modelGuid; }
	public function get vm():VoxelModel { return _vm; }
	public function get parentModelGuid():String { return _parentModelGuid; }
	
	public function ModelLoadingEvent( $type:String, $modelGuid:String, $parentModelGuid:String = "", $vm:VoxelModel = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_modelGuid = $modelGuid;
		_parentModelGuid = $parentModelGuid;
		_vm = $vm;
	}
	
	public override function clone():Event
	{
		return new ModelLoadingEvent(type, _modelGuid, _parentModelGuid, _vm, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("ModelLoadingEvent", "modelGuid", "parentModelGuid", "vm" );
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

	static public function dispatch( $event:ModelLoadingEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}

	///////////////// Event handler interface /////////////////////////////
	
}
}
