/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel {

import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.PersistenceObject;

import playerio.DatabaseObject;

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

public class PermissionsModel extends PermissionsBase
{
    static public const COPY_COUNT:int			= -1;

    // All the binds need to be tested
    static public const BIND_NONE:String 		= "BIND_NONE";
    static public const BIND_PICKUP:String 		= "BIND_PICKUP";
    static public const BIND_USE:String 		= "BIND_USE";
    static public const BIND_MODIFY:String 		= "BIND_MODIFY";
    static public const BIND_CURSE:String 		= "BIND_CURSE";

    static public const MODIFY_VOXEL:int            = 2;
    static public const MODIFY_CHILD_REMOVE:int     = 4;
    static public const MODIFY_CHILD_ADD:int 	    = 8;
    static public const MODIFY_SCRIPT_REMOVE:int    = 16;
    static public const MODIFY_SCRIPT_MODIFY:int 	= 32;
    static public const MODIFY_SCRIPT_ADD:int 	    = 64;
    static public const MODIFY_ANI_REMOVE:int       = 128;
    static public const MODIFY_ANI_MODIFY:int 	    = 256;
    static public const MODIFY_ANI_ADD:int 	        = 512;
    static public const MODIFY_ANY:int 		        = 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512;
    static public const MODIFY_NONE:int 		    = 8192;

    static private var _s_lookup:Array              = [];
    static private var _s_initialized:Boolean       = false;
    static public function getTextFromModificationCode( $val:int ):String {
        if ( !_s_initialized ) {
            Log.out( "PermissionsModel.getTextFromModificationCode - NO COMPLETED", Log.WARN );
            _s_initialized = true;
            _s_lookup[MODIFY_ANY] = "Any modification";
            _s_lookup[MODIFY_VOXEL] = "Can change voxel model";
            _s_lookup[MODIFY_CHILD_REMOVE] = "Can remove children";
            _s_lookup[MODIFY_CHILD_ADD] = "Can add children";
            _s_lookup[MODIFY_SCRIPT_REMOVE] = "Can remove scripts";
            _s_lookup[MODIFY_SCRIPT_MODIFY] = "Can modify scripts";
            _s_lookup[MODIFY_SCRIPT_ADD] = "Can add scripts";
            _s_lookup[MODIFY_ANI_REMOVE] = "Can remove animations";
            _s_lookup[MODIFY_ANI_MODIFY] = "Can modify animations";
            _s_lookup[MODIFY_ANI_ADD] = "Can add animations";
            _s_lookup[MODIFY_NONE] = "No modifications allowed";
        }
        var outString:String = _s_lookup[MODIFY_ANY];
        // What should happen here is I should go thru each bit by shifting the $val to the right by one.
        // if that bits is 1, then it has that permission.
        return outString;
    }


    public function get modify():int 					{ return dbo.permissions.modify; }
    public function set modify(value:int):void 			{ dbo.permissions.modify = value; changed = true; }

    public function get copyCount():int  				{ return dbo.permissions.copyCount; }
    public function set copyCount(value:int):void  		{ dbo.permissions.copyCount = value; changed = true; }

    public function get binding():String 				{ return dbo.permissions.binding; }
    public function set binding(value:String):void  	{ dbo.permissions.binding = value; changed = true; }

    public function PermissionsModel() {
        super();
    }

    override public function fromObject( $owner:PersistenceObject ):void {
        var newPermissions:Boolean = true;
        if ( null == $owner )
            Log.out( "PermissionModel NULL OWNER", Log.WARN );
        if ( $owner && $owner.dbo && $owner.dbo.permissions && $owner.dbo.permissions.creator != "" )
            newPermissions = false;
        super.fromObject( $owner as PersistenceObject );

        if ( newPermissions ) {
            dbo.permissions.copyCount 			= COPY_COUNT;
            dbo.permissions.modify				= MODIFY_ANY;
            dbo.permissions.binding				= BIND_NONE;
        }
    }

    override public function toObject():Object {
        var o:Object = super.toObject();
        o.copyCount 						= copyCount;
        o.modify							= modify;
        o.binding							= binding;

        return o;
    }

}
}

