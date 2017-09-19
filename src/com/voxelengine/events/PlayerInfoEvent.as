/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.models.PlayerInfo;

import flash.events.Event;
import flash.events.EventDispatcher;

public class PlayerInfoEvent extends ModelBaseEvent
{
    private var _guid:String;
    private var _playerInfo:PlayerInfo;
    public function get guid():String { return _guid; }
    public function get playerInfo():PlayerInfo { return _playerInfo; }

    public function PlayerInfoEvent( $type:String, $guid:String, $playerInfo:PlayerInfo = null )
    {
        super( $type, 0 );
        _guid = $guid;
        _playerInfo = $playerInfo
    }

    public override function toString():String { return formatToString("PlayerInfoEvent", "guid" ); }
    public override function clone():Event { return new PlayerInfoEvent(type, _guid ); }

    ///////////////// Event handler interface /////////////////////////////

    // Used to distribute all modelInfo messages
    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static public  function create( $type:String, $guid:String, $playerInfo:PlayerInfo = null ):Boolean {
        return _eventDispatcher.dispatchEvent( new PlayerInfoEvent( $type, $guid, $playerInfo ) );
    }
    ///////////////// Event handler interface /////////////////////////////
}
}
