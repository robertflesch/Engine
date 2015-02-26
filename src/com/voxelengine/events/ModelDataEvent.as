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

import com.voxelengine.worldmodel.models.ModelData;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelDataEvent extends ModelBaseEvent
{
	//// tells us the manager has add this from persistance
	static public const ADDED:String						= "ADDED";
	//
	//// tells the manager to load this type of model
	static public const TYPE_REQUEST:String					= "TYPE_REQUEST";
	//// the response to this is the added message
	
	//// tells the manager to load this model
	static public const REQUEST:String						= "REQUEST";
	static public const REQUEST_FAILED:String				= "REQUEST_FAILED";
	
	static public const SAVE:String							= "SAVE";
	static public const SAVE_FAILED:String					= "SAVE_FAILED";
	
	private var _vmd:ModelData;
	private var _guid:String;

	public function ModelDataEvent( $type:String, $guid:String, $vmd:ModelData, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
		_vmd = $vmd;
		_guid = $guid;
	}
	
	public override function clone():Event
	{
		return new ModelDataEvent(type, _guid, _vmd, bubbles, cancelable);
	}
   
	public override function toString():String
	{
		return formatToString("ModelDataEvent", "bubbles", "cancelable") +  " guid: " + _guid;
	}
	
	public function get vmd():ModelData 
	{
		return _vmd;
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

	static public function dispatch( $event:ModelDataEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
