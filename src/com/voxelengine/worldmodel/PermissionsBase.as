/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import playerio.DatabaseObject;

import com.voxelengine.server.Network;
import com.voxelengine.Log;
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
public class PermissionsBase
{
	static public const COPY_COUNT:int			= 2048;
	
	// All the binds need to be tested
	static public const BIND_NONE:String 		= "BIND_NONE";
	static public const BIND_PICKUP:String 		= "BIND_PICKUP";
	static public const BIND_USE:String 		= "BIND_USE";
	static public const BIND_MODIFY:String 		= "BIND_MODIFY";
	
	private var _owner:Object;
	
	public function get blueprintGuid():String  			{ return _owner.permissions.blueprintGuid; }
	public function set blueprintGuid(value:String):void 	{ _owner.permissions.blueprintGuid = value; }

	public function get modify():Boolean 					{ return _owner.permissions.modify; }
	public function set modify(value:Boolean):void 			{ _owner.permissions.modify = value; }
			
	public function get modifiedDate():String 				{ return _owner.permissions.modifiedDate; }
	public function set modifiedDate(value:String):void		{ _owner.permissions.modifiedDate = value; }
			
	public function get copyCount():int  					{ return _owner.permissions.copyCount; }
	public function set copyCount(value:int):void  			{ _owner.permissions.copyCount = value; }
			
	public function get createdDate():String 				{ return _owner.permissions.createdDate; }
			
	public function get creator():String 					{ return _owner.permissions.creator; }
			
	public function get binding():String 					{ return _owner.permissions.binding; }
	public function set binding(value:String):void  		{ _owner.permissions.binding = value; }
			
	public function get blueprint():Boolean 				{ return _owner.permissions.blueprint; }
	public function set blueprint(value:Boolean):void		{ _owner.permissions.blueprint = value; }
	
	public function get owner():Object 						{ return _owner;}
	
	public function PermissionsBase( $owner:Object ) {
		_owner = $owner
		if ( !_owner.permissions )
			_owner.permissions = new Object()
			
		// If permissions already exist dont reset them.
		if ( _owner.permissions.createdDate || _owner.permissions.creator )
			return;
			
		_owner.permissions.copyCount 		= COPY_COUNT;
		_owner.permissions.modify			= true;
		_owner.permissions.blueprint		= false;
		_owner.permissions.blueprintGuid	= null;
		_owner.permissions.creator			= Network.userId;
		_owner.permissions.createdDate		= new Date().toUTCString();
		_owner.permissions.modifyDate		= new Date().toUTCString();
		_owner.permissions.binding			= BIND_NONE;
	}
}
}
