/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.events {
import flash.events.Event;
import flash.events.EventDispatcher;

public class LevelOfDetailEvent extends Event {
    static public const MODEL_CLONE_COMPLETE:String		= "MODEL_CLONE_COMPLETE";

    public function LevelOfDetailEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(type, bubbles, cancelable);
    }

    public override function clone():Event
    {
        return new LevelOfDetailEvent(type, bubbles, cancelable);
    }

    public override function toString():String
    {
        return formatToString("LevelOfDetailEvent", "modelGuid", "parentModelGuid", "vm" );
    }

    ///////////////// Event handler interface /////////////////////////////

    // Used to distribute all level of detail messages
    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static public function dispatch( $event:LevelOfDetailEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $event );
    }

    ///////////////// Event handler interface /////////////////////////////

}
}

