
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
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;
/**
 * ...
 * @author Robert Flesch - RSF
 */
public class TextureLoadingEvent extends Event
{
    static public const REQUEST:String  	= "REQUEST";
    static public const LOAD_SUCCEED:String  	= "LOAD_SUCCEED";
    static public const LOAD_FAILED:String  	= "LOAD_FAILED";
    static public const LOAD_NOT_FOUND:String 	= "LOAD_NOT_FOUND";

    private var _name:String;
    public function get name():String { return _name; }

    private var _data:*;
    public function get data():* { return _data; }

    public function TextureLoadingEvent( $type:String, $name:String, $data:* = null ){
        super( $type );
        _name = $name;
        _data = $data;
    }

    public override function clone():Event {
        return new TextureLoadingEvent(type, _name, _data );
    }

    public override function toString():String {
        return formatToString("PersistenceEvent", "type", "name", "data" );
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

    static public function dispatch( $event:PersistenceEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $event );
    }

    static public function create( $type:String, $name:String, $data:* = null ):Boolean {
        return _eventDispatcher.dispatchEvent( new TextureLoadingEvent( $type, $name, $data ) );
    }

    ///////////////// Event handler interface /////////////////////////////
}
}