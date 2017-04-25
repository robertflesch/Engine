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

public class CharacterSlotEvent extends Event {

    static public const SLOT_CHANGE:String  			= "SLOT_CHANGE";
    static public const DEFAULT_REQUEST:String  		= "DEFAULT_REQUEST";


    private var _owner:String; // Guid of model which is implementing this action
    public function get owner():String { return _owner; }
    private var _slot:String;
    public function get slot():String { return _slot; }
    private var _guid:String;
    public function get guid():String { return _guid; }

    public function CharacterSlotEvent( $type:String, $owner:String, $slot:String, $guid:String ) {
        super( $type );
        _owner = $owner;
        _slot = $slot;
        _guid = $guid;
    }

    public override function clone():Event {
        return new CharacterSlotEvent( type, _owner, _slot, _guid );
    }

    public override function toString():String {
        return formatToString("CharacterSlotEvent", "owner", "slotId", "data" );
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

    static public function create( $type:String, $owner:String, $slot:String, $guid:String ) : Boolean {
        return _eventDispatcher.dispatchEvent( new CharacterSlotEvent( $type, $owner, $slot, $guid ) );
    }

    ///////////////// Event handler interface /////////////////////////////
}
}
