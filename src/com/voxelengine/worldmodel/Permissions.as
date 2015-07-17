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
public class Permissions
{
	static public const COPY_COUNT:int			= 2048;
	static public const BIND_NONE:String 		= "BIND_NONE";
	static public const BIND_PICKUP:String 		= "BIND_PICKUP";
	static public const BIND_USE:String 		= "BIND_USE";
	static public const BIND_MODIFY:String 		= "BIND_MODIFY";
	
	private var _permissions:Object;
	
	public function get blueprintGuid():String  			{ return _permissions.blueprintGuid; }
	public function set blueprintGuid(value:String):void 	{ _permissions.blueprintGuid = value; }

	public function get modify():Boolean 				{ return _permissions.modify; }
	public function set modify(value:Boolean):void 		{ _permissions.modify = value; }
	
	public function get modifiedDate():Date 			{ return _permissions.modifiedDate; }
	public function set modifiedDate(value:Date):void  	{ _permissions.modifiedDate = value; }
	
	public function get copyCount():int  				{ return _permissions.copyCount; }
	public function set copyCount(value:int):void  		{ _permissions.copyCount = value; }
	
	public function get createdDate():Date 					{ return _permissions.createdDate; }
	
	public function get creator():String 				{ return _permissions.creator; }
	
	public function get binding():String 				{ return _permissions.binding; }
	public function set binding(value:String):void  	{ _permissions.binding = value; }
	
	public function get blueprint():Boolean 				{ return _permissions.blueprint; }
	public function set blueprint(value:Boolean):void 		{ _permissions.blueprint = value; }
	
	public function Permissions( $permissions:Object ) {
		_permissions = $permissions;
		if ( $permissions.copyCount )
			return;
			
		$permissions.copyCount 		= COPY_COUNT;
		$permissions.modify			= true;
		$permissions.blueprint		= false;
		$permissions.blueprintGuid	= null;
		$permissions.creator		= Network.userId;
		$permissions.createdDate	= new Date();
		$permissions.binding		= BIND_NONE;
	}
	/*
	public function clone():Permissions {
		var newP:Permissions = new Permissions();
		newP.copyCount 		= _copyCount;
		newP.modify			= _modify;
		newP.blueprintGuid	= new String( _blueprintGuid );
		newP.creator		= new String( _creator );
		newP.createdDate	= _createdDate;
		newP.binding		= new String( _binding );
		return newP;
	}
	*/
}
}
