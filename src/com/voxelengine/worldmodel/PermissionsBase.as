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
	
	public function get modifiedDate():String 				{ return _dboReference.permissions.modifiedDate; }
	public function set modifiedDate(value:String):void		{ _dboReference.permissions.modifiedDate = value; }
			
	public function get createdDate():String 				{ return _dboReference.permissions.createdDate; }
			
	public function get creator():String 					{ return _dboReference.permissions.creator; }
			
	public function get dboReference():Object 				{ return _dboReference;}
	
	public function PermissionsBase( $dboReference:DatabaseObject ) {
		_dboReference = $dboReference;
		if ( !_dboReference.permissions )
			_dboReference.permissions = {};
			
		// If permissions already exist dont reset them.
		if ( _dboReference.permissions.createdDate || _dboReference.permissions.creator )
			return;
			
		modifiedDate						= new Date().toUTCString();
		_dboReference.permissions.creator	= Network.userId;
		_dboReference.permissions.createdDate = new Date().toUTCString();
	}
}
}
