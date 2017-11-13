/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.worldmodel.models.PersistenceObject;

import playerio.DatabaseObject;
import com.voxelengine.server.Network;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 * Similar to SecondLife permissions.
 * http://wiki.secondlife.com/wiki/Permissions_FAQ
 * https://community.secondlife.com/t5/English-Knowledge-Base/Object-permissions/ta-p/700129
 * http://wiki.secondlife.com/wiki/Permission
 * Modify - modify
 * Copy - copy count
 * Transfer - Bind
 * Move - if you are owningModel, you can change.
 */
public class PermissionsBase {
    protected var _owner:PersistenceObject;
    protected function get owner():PersistenceObject 			{ return _owner; }
    protected function set owner($val:PersistenceObject):void  	{ _owner = $val; }

    protected function get dbo():DatabaseObject 				{ return _owner.dbo; }


    public function get modifiedDate():String 				{ return dbo.permissions.modifiedDate; }
    public function get creator():String 					{ return dbo.permissions.creator; }
    public function get createdDate():String 				{ return dbo.permissions.createdDate; }

	public function PermissionsBase() {
	}

    public function fromObject( $owner:PersistenceObject ):void {
        owner = $owner;
        if ( !dbo.permissions ) {
            dbo.permissions = {};
            dbo.permissions.creator = Network.userId;
            dbo.permissions.createdDate = new Date().toUTCString();
            dbo.permissions.modifiedDate = new Date().toUTCString();
        }
    }

    public function toObject():Object {
        var o:Object = {};
        o.creator								= creator;
        o.createdDate							= createdDate;
        o.modifiedDate 							= modifiedDate;

		return o;
    }

	protected function set changed( $val:Boolean ):void {
        dbo.permissions.modifiedDate = new Date().toUTCString();
		owner.changed = true;
	}
}
}
