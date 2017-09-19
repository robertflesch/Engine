/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models {
import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PlayerInfoEvent;

import flash.utils.Dictionary;

public class PlayerInfoCache
{
    static public const BIGDB_TABLE_PLAYEROBJECTS:String = "playerInfo";
    static public const BIGDB_TABLE_PLAYEROBJECTS_CREATOR:String = "creator";

    static private var _playerInfo:Dictionary = new Dictionary(false);
    static private var _block:Block = new Block();

    // This is required to be public.
    public function PlayerInfoCache() {}

    static public function init():void {
        // These are the requests that are handled
        PlayerInfoEvent.addListener( ModelBaseEvent.REQUEST, 			request );
        PlayerInfoEvent.addListener( ModelBaseEvent.SAVE, 				saveHandler );
        PlayerInfoEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );

        // These are the events at the persistence layer
        PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    //  PlayerInfoEvents
    /////////////////////////////////////////////////////////////////////////////////////////////
    static public function saveHandler( $pie:PlayerInfoEvent ):void {
        PlayerInfoEvent.create( ModelBaseEvent.DELETE, $pie.guid, $pie.playerInfo );
        var pi:PlayerInfo = $pie.playerInfo;
        pi.save();
    }

    static public function deleteHandler( $pie:PlayerInfoEvent ):void {
        PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, 1, BIGDB_TABLE_PLAYEROBJECTS, $pie.playerInfo.creator, null, BIGDB_TABLE_PLAYEROBJECTS_CREATOR ) );
    }

    static private function request( $pie:PlayerInfoEvent ):void {
        if ( null == $pie || null == $pie.guid ) { // Validator
            Log.out( "PlayerInfoCache.request requested event or guid is NULL: ", Log.ERROR );
            PlayerInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, ($pie ? $pie.guid : null), null );
        } else {
            //Log.out( "PlayerInfoCache.PlayerInfoRequest guid: " + $pie.modelGuid, Log.INFO );
            var pi:PlayerInfo = _playerInfo[$pie.guid];
            if (null == pi) {
                if (_block.has($pie.guid))
                    return;
                _block.add($pie.guid);

                if (true == Globals.online)
                    PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.LOAD_REQUEST, 0, BIGDB_TABLE_PLAYEROBJECTS, $pie.guid));
            }
            else {
                if ($pie)
                    PlayerInfoEvent.create(ModelBaseEvent.RESULT, $pie.guid, pi);
                else
                    Log.out("PlayerInfoCache.request PlayerInfoEvent is NULL: ", Log.WARN);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    //  PlayerInfoEvent
    /////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    //  Internal Methods
    /////////////////////////////////////////////////////////////////////////////////////////////
    static private function add( $series:int, $pi:PlayerInfo ):void {
        if ( null == $pi || null == $pi.guid ) {
            //Log.out( "PlayerInfoCache.add trying to add NULL PlayerInfo or guid", Log.WARN );
            return;
        }
        // check to make sure is not already there
        if ( null ==  _playerInfo[$pi.guid] ) {
            //Log.out( "PlayerInfoCache.add PlayerInfo: " + $pi.toString(), Log.DEBUG );
            _playerInfo[$pi.guid] = $pi;

            PlayerInfoEvent.create( ModelBaseEvent.ADDED, $pi.guid, $pi );
        }
    }

import com.voxelengine.Globals;
import com.voxelengine.events.PersistenceEvent;

/////////////////////////////////////////////////////////////////////////////////////////////
    //  Persistence Events
    /////////////////////////////////////////////////////////////////////////////////////////////
    static private function loadSucceed( $pe:PersistenceEvent):void {
        if ( BIGDB_TABLE_PLAYEROBJECTS != $pe.table )
            return;

        if ( 1 == $pe.series ){
            if ($pe.dbo) {
                // TODO so question is does this delete the newly added record?
                PersistenceEvent.create( PersistenceEvent.DELETE_REQUEST, $pe.series, BIGDB_TABLE_PLAYEROBJECTS, $pe.guid );
            }
        } else {
            var pi:PlayerInfo = _playerInfo[$pe.guid];
            if (null != pi) {
                // we already have it, publishing this results in duplicate items being sent to inventory window.
                PlayerInfoEvent.create(ModelBaseEvent.ADDED, $pe.guid, pi);
                Log.out("PlayerInfoCache.loadSucceed - attempting to load duplicate PlayerInfo guid: " + $pe.guid, Log.WARN);
                return;
            }

            if ($pe.dbo) {
                pi = new PlayerInfo($pe.guid, $pe.dbo);
                add($pe.series, pi);
            } else {
                PlayerInfoEvent.create(ModelBaseEvent.REQUEST_FAILED, null, null);
            }
        }
    }

    static private function loadFailed( $pe:PersistenceEvent ):void {
        if ( BIGDB_TABLE_PLAYEROBJECTS != $pe.table )
            return;
        Log.out( "PlayerInfoCache.loadFailed PersistenceEvent: " + $pe.toString(), Log.WARN );
        if ( _block.has( $pe.guid ) )
            _block.clear( $pe.guid );
        PlayerInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.guid, null );
    }

    static private function loadNotFound( $pe:PersistenceEvent):void {
        if ( BIGDB_TABLE_PLAYEROBJECTS != $pe.table )
            return;
        Log.out( "PlayerInfoCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
        if ( _block.has( $pe.guid ) )
            _block.clear( $pe.guid );
        PlayerInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.guid, null );
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    //  End - Persistence Events
    /////////////////////////////////////////////////////////////////////////////////////////////
}
}