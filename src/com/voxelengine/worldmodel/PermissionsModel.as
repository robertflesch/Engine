/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel {

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
 * Move - if you are owner, you can change.
 */

public class PermissionsModel extends PermissionsBase
{
    static public const COPY_COUNT:int			= 2048;

    // All the binds need to be tested
    static public const BIND_NONE:String 		= "BIND_NONE";
    static public const BIND_PICKUP:String 		= "BIND_PICKUP";
    static public const BIND_USE:String 		= "BIND_USE";
    static public const BIND_MODIFY:String 		= "BIND_MODIFY";

    public function get blueprintGuid():String  			{ return _dboReference.permissions.blueprintGuid; }
    public function set blueprintGuid(value:String):void 	{ _dboReference.permissions.blueprintGuid = value; }

    public function get modify():Boolean 					{ return _dboReference.permissions.modify; }
    public function set modify(value:Boolean):void 			{ _dboReference.permissions.modify = value; }

    public function get copyCount():int  					{ return _dboReference.permissions.copyCount; }
    public function set copyCount(value:int):void  			{ _dboReference.permissions.copyCount = value; }

    public function get binding():String 					{ return _dboReference.permissions.binding; }
    public function set binding(value:String):void  		{ _dboReference.permissions.binding = value; }

    public function get blueprint():Boolean 				{ return _dboReference.permissions.blueprint; }
    public function set blueprint(value:Boolean):void		{ _dboReference.permissions.blueprint = value; }

    public function PermissionsModel( $dboReference:DatabaseObject ) {
        super( $dboReference );

        copyCount 							= COPY_COUNT;
        modify								= true;
        blueprint							= false;
        blueprintGuid						= null;
        binding								= BIND_NONE;
    }
}
}
