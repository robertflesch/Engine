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
	static public const LARGEST_INT:int			= 2147483647;
	static public const BIND_NONE:String 		= "BIND_NONE";
	static public const BIND_PICKUP:String 		= "BIND_PICKUP";
	static public const BIND_USE:String 		= "BIND_USE";
	static public const BIND_MODIFY:String 		= "BIND_MODIFY";
	
	private var _copyCount:int 			= LARGEST_INT;		// Can this object be copied? -1 is no copy 0 - n is the number of copies remaining.
	private var _modify:Boolean			= true;				// Can this object be modified
	private var _creator:String 		= Network.userId;;	// The guid of the original creator
	private var _createdDate:Date		= new Date();		// Date created
	private var _binding:String			= BIND_NONE;		// Bind type (see above)
	private var _blueprint:Boolean		= false;			// is this only a blue print for other objects.
	private var _blueprintGuid:String 	= null;				// Is this object based on something else? if so track the guid of original object
	
	public function get blueprintGuid():String  			{ return _blueprintGuid; }
	public function set blueprintGuid(value:String):void { _blueprintGuid = value; }

	public function get modify():Boolean 				{ return _modify; }
	public function set modify(value:Boolean):void 		{ _modify = value; }
	
	public function get copyCount():int  				{ return _copyCount; }
	public function set copyCount(value:int):void  		{ _copyCount = value; }
	
	public function get createdDate():Date 					{ return _createdDate; }
	public function set createdDate(value:Date):void 		{ _createdDate = value; }
	
	public function get creator():String 				{ return _creator; }
	public function set creator(value:String):void  	{ _creator = value; }
	
	public function get binding():String 				{ return _binding; }
	public function set binding(value:String):void  	{ _binding = value; }
	
	public function get blueprint():Boolean 				{ return _blueprint; }
	public function set blueprint(value:Boolean):void 		{ _blueprint = value; }
	
	public function Permissions() {
		
	}
	
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
	
	public function toPersistance( _dbo:DatabaseObject ):void {
		_dbo.copyCount 		= _copyCount;
		_dbo.modify			= _modify;
		_dbo.templateGuid	= _blueprintGuid;
		_dbo.creator		= _creator;
		_dbo.createdDate	= _dbo._createdDate ? _dbo._createdDate : new Date();
		_dbo.binding		= _binding;
	}
	
	public function fromPersistance( _dbo:DatabaseObject ):void {
		_copyCount		= _dbo.copyCount;
		_modify			= _dbo.modify;		
		_blueprintGuid	= _dbo.templateGuid;
		_creator		= _dbo.creator;
		_createdDate	= _dbo._createdDate ? _dbo._createdDate : new Date();
		_binding		= _dbo.binding;
	}
	
	public function addToObject( metadataObj:Object ):Object {
		metadataObj.copyCount 	= _copyCount;
		metadataObj.modify		= _modify;
		metadataObj.templateGuid= _blueprintGuid;
		metadataObj.creator		= _creator;
		metadataObj.createdDate	= _createdDate ? _createdDate : new Date();
		metadataObj.binding		= _binding;
		return metadataObj;
	}
}
}
