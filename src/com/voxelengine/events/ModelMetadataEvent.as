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
import com.voxelengine.worldmodel.models.VoxelModelMetadata;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelMetadataEvent extends Event
{
	//// tells us the manager has add this from persistance
	static public const ADDED:String						= "ADDED";
	//
	//// tells the manager to load this type of model
	static public const TYPE_REQUEST:String					= "TYPE_REQUEST";
	//// the response to this is the added message
	
	//// tells the manager to load this model
	static public const REQUEST:String						= "REQUEST";
		
	static public const FAILED:String						= "FAILED";
	static public const SAVE:String							= "SAVE";
	//
	
	//// data or meta data about this region has changed
	//static public const REGION_CHANGED:String					= "REGION_CHANGED";
	//
	//// dispatched when a region is unloaded
	//static public const REGION_UNLOAD:String					= "REGION_UNLOAD";
	//// tells the region manager to load this region
	//static public const REGION_LOAD:String						= "REGION_LOAD";
	//// dispatched after jobs for all process have been added
	//static public const REGION_LOAD_BEGUN:String				= "REGION_LOAD_BEGUN";
	//// tells the region manager this region had finished loading
	//static public const REGION_LOAD_COMPLETE:String				= "REGION_LOAD_COMPLETE";
	//
	//
	//// Used by the sandbox list and config manager to request a join of a server region
	//static public const REQUEST_JOIN:String						= "REQUEST_JOIN";
	
//		private var _dbo:DatabaseObject;
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
