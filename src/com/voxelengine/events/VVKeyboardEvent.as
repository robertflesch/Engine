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
import flash.events.KeyboardEvent;
import flash.events.KeyboardEvent;

public class VVKeyboardEvent extends KeyboardEvent {

    public function VVKeyboardEvent( $type:String, $charCodeValue:uint = 0, $keyCodeValue:uint = 0, $keyLocationValue:uint = 0, $ctrlKeyValue:Boolean = false, $altKeyValue:Boolean = false, $shiftKeyValue:Boolean = false):void {
        super( $type, bubbles, cancelable, $charCodeValue, $keyCodeValue, $keyLocationValue, $ctrlKeyValue, $altKeyValue, $shiftKeyValue );
    }

    public override function clone():Event {
        return new VVKeyboardEvent(type, charCode, keyCode, keyLocation, ctrlKey, altKey, shiftKey );
    }

    public override function toString():String {
        return formatToString("KBEvent", "type", "charCode", "keyCode", "keyLocation", "ctrlKey", "altKey", "shiftKey");
    }

    ///////////////// Event handler interface /////////////////////////////
    // Used to distribute all persistence messages
    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        trace( "VVKeyboardEvent - addListener: " + $type );
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static public function dispatch( $e:KeyboardEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $e );
    }

    static public function create( $type:String, $charCodeValue:uint = 0, $keyCodeValue:uint = 0, $keyLocationValue:uint = 0, $ctrlKeyValue:Boolean = false, $altKeyValue:Boolean = false, $shiftKeyValue:Boolean = false ) : Boolean {
        return dispatch( new VVKeyboardEvent( $type, $charCodeValue, $keyCodeValue, $keyLocationValue, $ctrlKeyValue, $altKeyValue, $shiftKeyValue ) );
    }
    ///////////////// Event handler interface /////////////////////////////
}
}
