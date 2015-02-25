/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.models.VoxelModelData;
import flash.events.Event;
import flash.utils.ByteArray;
import com.voxelengine.worldmodel.models.ModelInfo;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelInfoEvent extends Event
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
	
	private var _vmi:ModelInfo;
	private var _guid:String;

	public function ModelInfoEvent( $type:String, $guid:String, $vmi:ModelInfo, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_vmi = $vmi;
		_guid = $guid;
	}
	
	public override function clone():Event
	{
		return new ModelInfoEvent(type, _guid, _vmi, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("ModelInfoEvent", "guid", "vmi" );
	}
	
	public function get vmi():ModelInfo 
	{
		return _vmi;
	}
	
	public function get guid():String 
	{
		return _guid;
	}
	///////////////// Event handler interface /////////////////////////////

	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function hasEventListener( $type:String ) : Boolean {
		return _eventDispatcher.hasEventListener( $type );
	}
	
	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:ModelInfoEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
