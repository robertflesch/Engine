/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event;
import flash.utils.ByteArray;
import flash.events.EventDispatcher;

import com.voxelengine.worldmodel.models.VoxelModelMetadata;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelMetadataEvent extends ModelBaseEvent
{
	private var _vmm:VoxelModelMetadata;
	private var _guid:String;

	public function ModelMetadataEvent( $type:String, $guid:String, $vmm:VoxelModelMetadata, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_vmm = $vmm;
		_guid = $guid;
	}
	
	public override function clone():Event
	{
		return new ModelMetadataEvent(type, _guid, _vmm, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("ModelMetadataEvent", "bubbles", "cancelable") + " VoxelModelMetadata: " + _vmm.toString() + "  itemGuid: " + _guid;
	}
	
	public function get vmm():VoxelModelMetadata 
	{
		return _vmm;
	}
	
	public function get guid():String 
	{
		return _guid;
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

	static public function dispatch( $event:ModelMetadataEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
