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

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 * Similar to SecondLife permissions.
 * http://wiki.secondlife.com/wiki/Permissions_FAQ
 * https://community.secondlife.com/t5/English-Knowledge-Base/Object-permissions/ta-p/700129
 * http://wiki.secondlife.com/wiki/Permission
 * 
 */
public class PermissionsRegion extends PermissionsBase
{
	//private var _editors:Vector.<String> = new Vector.<String>() //{ user Id1:role, user id2:role... }
	//private var _admins:Vector.<String> = new Vector.<String>() // : { user Id1:role, user id2:role... }
	//
	//public function get admins():Vector.<String>  { return _admins; }
	//public function set admins(value:Vector.<String>):void { _admins = value; }
	//public function get editors():Vector.<String> { return _editors; }
	//public function set editors(value:Vector.<String>):void  { _editors = value; }
	
	public function get created():String  { return dboReference.permissions.created; }
	public function set created(value:String):void  { dboReference.permissions.created = value; }
	public function get modified():String  { return dboReference.permissions.modified; }
	public function set modified(value:String):void  { dboReference.permissions.modified = value; }
	public function get guest():Boolean  { return dboReference.permissions.guest; }
	public function set guest(value:Boolean):void  { dboReference.permissions.guest = value; }

	public function PermissionsRegion( $dboReference:DatabaseObject ) {
		super( $dboReference );

		if ( !dboReference.permissions.guests )
			dboReference.permissions.guests = false;
		//$info.permissions.editors = [];
		//$info.permissions.admins = [];
	}

	public function toObject():Object {
		//_permissions.editors = editorsListGet();
		//_permissions.admins = adminsListGet();
		return dboReference.permissions;
	}

	//private function editorsListGet():String { return _editors.toString(); }
	//private function adminsListGet():String { return _admins.toString(); }
	
	////////////////////////////////////////
	// comma seperated variables
	private function cvsToVector( value:String ):Vector.<String> {
		var v:Vector.<String> = new Vector.<String>;
		var start:int = 0;
		var end:int = value.indexOf( ",", 0 );
		while ( -1 < end ) {
			v.push( value.substring( start, end ) );
			start = end + 1;
			end = value.indexOf( ",", start );
		}
		// there is only one, or this is the last one
		if ( -1 == end && start < value.length ) {
			v.push( value.substring( start, value.length ) );
		}
		return v;
	}
	
}
}
