/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models {
import com.voxelengine.Log;
import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.PersistenceEvent;

import flash.utils.Dictionary;

public class RoleCache {

    static public const BIGDB_TABLE_ROLES_INDEX:String = "public";

    static private var _roles:Dictionary = new Dictionary(false);
    
    public function RoleCache() {
    }

    static public function init():void {
        LoginEvent.addListener( LoginEvent.LOGIN_SUCCESS, online );
    }

    static private function online( $e:LoginEvent ):void {
        LoginEvent.removeListener( LoginEvent.LOGIN_SUCCESS, online );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
        PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, 0, Role.BIGDB_TABLE_ROLES, "true", null, BIGDB_TABLE_ROLES_INDEX ) );
    }

    static public function roleGet( $roleID:String ):Role {
        var role:Role = _roles[ $roleID ];
        if ( null == role )
            Log.out( "RoleCache.roleGet ERROR - NO ROLE WITH ID: " + $roleID + " found", Log.ERROR );
        return role;
    }

    static private function loadSucceed( $pe:PersistenceEvent ):void {
        if ( Role.BIGDB_TABLE_ROLES != $pe.table )
            return;

        var role:Role = _roles[$pe.guid];
        if ( null != role ) {
            Log.out( "RoleCache.loadSucceed - attempting to load duplicate RoleCache guid: " + $pe.guid, Log.WARN );
            return;
        }

        if ( $pe.dbo ) {
            role = new Role( $pe.guid, $pe.dbo );
            add( role );
        } else if ( $pe.data ) {
            Log.out( "RoleCache.loadSucceed - NO database object for guid: " + $pe.guid, Log.ERROR );
        }
    }

    static private function loadFailed( $pe:PersistenceEvent ):void  {
        if ( Role.BIGDB_TABLE_ROLES != $pe.table )
            return;
        Log.out( "RoleCache.LoadFailed PersistenceEvent: " + $pe.toString(), Log.ERROR );
    }

    static private function loadNotFound( $pe:PersistenceEvent):void {
        if ( Role.BIGDB_TABLE_ROLES != $pe.table )
            return;
        Log.out( "RoleCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
    }

    static private function add( $role:Role ):void {
        if ( null == $role || null == $role.guid ) {
            Log.out( "RoleCache.add trying to add NULL role or guid", Log.WARN );
            return;
        }
        // check to make sure is not already there
        if ( null ==  _roles[$role.guid] ) {
            //Log.out( "RoleCache.add vmm: " + $role.guid, Log.WARN );
            _roles[$role.guid] = $role;
        }
    }
    
}
}
