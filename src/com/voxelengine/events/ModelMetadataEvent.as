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

import com.voxelengine.worldmodel.models.ModelMetadata;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class ModelMetadataEvent extends ModelBaseEvent
{
	static public const RESULT_CHILDREN:String					= "RESULT_CHILDREN";

	private var _modelMetadata:ModelMetadata;
	private var _modelGuid:String;

	public function get modelMetadata():ModelMetadata { return _modelMetadata; }
	public function get modelGuid():String { return _modelGuid; }
	
	public override function clone():Event { return new ModelMetadataEvent(type, series, _modelGuid, _modelMetadata, bubbles, cancelable); }
	public override function toString():String { return formatToString("ModelMetadataEvent", "modelGuid", "modelMetadata" ); }
	
	public function ModelMetadataEvent( $type:String, $series:int, $modelGuid:String, $modelMetadata:ModelMetadata, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $series, $bubbles, $cancellable );
		_modelMetadata = $modelMetadata;
		_modelGuid = $modelGuid;
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
