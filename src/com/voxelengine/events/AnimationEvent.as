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

import com.voxelengine.worldmodel.animation.Animation;

public class AnimationEvent extends ModelBaseEvent
{
	private var _aniGuid:String; // animation guid or fileName
	private var _modelGuid:String; // Owners guid
	private var _ani:Animation;
	private var _fromTable:Boolean;

	public function get aniGuid():String  { return _aniGuid; }
	public function get modelGuid():String  { return _modelGuid; }
	public function get fromTable():Boolean  { return _fromTable; }
	public function get ani():Animation  { return _ani; }
	
	public function AnimationEvent( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $series, $bubbles, $cancellable );
		_modelGuid = $modelGuid;
		_aniGuid = $aniGuid;
		_fromTable = $fromTable;
		_ani = $ani;
	}
	
	public override function clone():Event {
		return new AnimationEvent(type, series, _modelGuid, _aniGuid, _ani, bubbles, cancelable);
	}
   
	public override function toString():String {
		return formatToString("AnimationEvent", "series", "modelGuid", "aniGuid", "ani" );
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

	static public function create( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true ) : Boolean {
		return _eventDispatcher.dispatchEvent( new AnimationEvent( $type, $series, $modelGuid, $aniGuid, $ani, $fromTable) );
	}

	static public function dispatch( $ae:AnimationEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $ae );
	}

	///////////////// Event handler interface /////////////////////////////
}
}
