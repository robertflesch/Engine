/*==============================================================================
Copyright 2011-2015 Robert Flesch
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
 * 
 */
public class PermissionsRegion
{
	private var _permissions:Object;
	//private var _editors:Vector.<String> = new Vector.<String>() //{ user Id1:role, user id2:role... }
	//private var _admins:Vector.<String> = new Vector.<String>() // : { user Id1:role, user id2:role... }
	//
	//public function get admins():Vector.<String>  { return _admins; }
	//public function set admins(value:Vector.<String>):void { _admins = value; }
	//public function get editors():Vector.<String> { return _editors; }
	//public function set editors(value:Vector.<String>):void  { _editors = value; }
	
	public function get created():Date  { return _permissions.created; }
	public function set created(value:Date):void  { _permissions.created = value; }
	public function get modified():Date  { return _permissions.modified; }
	public function set modified(value:Date):void  { _permissions.modified = value; }	
	public function get guest():Boolean  { return _permissions.guest; }
	public function set guest(value:Boolean):void  { _permissions.guest = value; }	

	public function PermissionsRegion( $info:Object ) {
		if ( $info.permissions ) {
			_permissions = $info.permissions;
			//if ( _permissions.editors )
				//_editors = cvsToVector( _permissions.editors );
			//if ( _permissions.admins )
				//_admins = cvsToVector( _permissions.admins );
		} else {
			$info.permissions = new Object();
			_permissions = $info.permissions;
			$info.permissions.created = new Date();
			$info.permissions.modified = new Date();
			$info.permissions.guests = false;
			//$info.permissions.editors = [];
			//$info.permissions.admins = [];
		}
	}

	public function toObject():Object {
		//_permissions.editors = editorsListGet();
		//_permissions.admins = adminsListGet();
		return _permissions;
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
