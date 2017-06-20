/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.events {
import flash.display.InteractiveObject;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;

public class VVMouseEvent extends MouseEvent {
    public function VVMouseEvent(type:String, localX:Number = 0, localY:Number = 0, relatedObject:InteractiveObject = null, ctrlKey:Boolean = false, altKey:Boolean = false, shiftKey:Boolean = false, buttonDown:Boolean = false, delta:int = 0) {
        super(type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
    }

    public override function clone():Event {
        return new VVMouseEvent( type, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta );
    }

    public override function toString():String {
        return formatToString("VVMouseEvent", "type", "localX", "localY");
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

    static public function dispatch( $e:MouseEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $e );
    }
    ///////////////// Event handler interface /////////////////////////////
}
}
