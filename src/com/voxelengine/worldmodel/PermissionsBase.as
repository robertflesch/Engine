/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;

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
 * Move - if you are owner, you can change.
 */
public class PermissionsBase {
	protected var _dboReference:DatabaseObject;
    protected function get dboReference():DatabaseObject { return _dboReference; }

	public function get modifiedDate():String 				{ return _dboReference.permissions.modifiedDate; }
	public function get creator():String 					{ return _dboReference.permissions.creator; }
	public function get createdDate():String 				{ return _dboReference.permissions.createdDate; }

    private var _guid:String;

	public function PermissionsBase( $dboReference:DatabaseObject, $guid:String ) {
        _guid = $guid;
		_dboReference = $dboReference;
		if ( !_dboReference.permissions ) {
            _dboReference.permissions = {};
            _dboReference.permissions.creator = Network.userId;
            _dboReference.permissions.createdDate = new Date().toUTCString();
            _dboReference.permissions.modifiedDate = new Date().toUTCString();
            changed = true;
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
        _dboReference.permissions.modifiedDate = new Date().toUTCString();
		ModelMetadataEvent.create( ModelBaseEvent.CHANGED, 0, _guid );
	}
}
}
