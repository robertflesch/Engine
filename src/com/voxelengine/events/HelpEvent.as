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

public class HelpEvent extends Event {
    static public const CREATE:String					= "CREATE";
    static public const CLOSED:String					= "CLOSED";

    private var _textFileName:String = "";
    public function textFileName():String { return _textFileName; }

    public function HelpEvent(type:String, $textFileName:String = "" ) {
        super(type, bubbles, cancelable);
        _textFileName = $textFileName;
    }

    public override function toString():String { return formatToString("HelpEvent", "textFileName", "type" ); }
    public override function clone():Event { return new HelpEvent(type, _textFileName); }

    ///////////////// Event handler interface /////////////////////////////

    // Used to distribute all modelInfo messages
    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function hasEventListener( $type:String ) : Boolean {
        return _eventDispatcher.hasEventListener( $type );
    }

    static public function add( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function remove( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static public  function create( $type:String, $textFileName:String = "" ):Boolean {
        return _eventDispatcher.dispatchEvent( new HelpEvent( $type ) );
    }
    ///////////////// Event handler interface /////////////////////////////
}
}
