/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
	import com.voxelengine.server.Network;
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
public class Permissions
{
	static public const LARGEST_INT:int			= 2147483647;
	static public const TEMPLATE_NONE:String	= "NONE";
	static public const BIND_NONE:String 		= "BIND_NONE";
	static public const BIND_PICKUP:String 		= "BIND_PICKUP";
	static public const BIND_USE:String 		= "BIND_USE";
	static public const BIND_MODIFY:String 		= "BIND_MODIFY";
	
	private var _copyCount:int 			= LARGEST_INT;		// Can this object be copied? -1 is no copy 0 - n is the number of copies remaining.
	private var _modify:Boolean			= true;				// Can this object be modified
	private var _templateGuid:String 	= null;				// Is this object based on something else? if so track the guid of original object
	private var _creator:String 		= Network.userId;;	// The guid of the original creator
	private var _created:Date			= new Date();		// Date created
	private var _binding:String			= BIND_NONE;		// Bind type (see above)
	
	public function dboSetInfo( _dbo:DatabaseObject ):void {
		_dbo.copyCount 		= _copyCount;
		_dbo.modify			= _modify;
		_dbo.templateGuid	= _templateGuid;
		_dbo.creator		= _creator;
		_dbo.created		= _created;
		_dbo.binding		= _binding;
	}
	
	public function fromDbo( _dbo:DatabaseObject ):void {
		_copyCount		= _dbo.copyCount;
		_modify			= _dbo.modify;		
		_templateGuid	= _dbo.templateGuid;
		_creator		= _dbo.creator;
		_created		= _dbo.created;
		_binding		= _dbo.binding;
	}
	
	public function addToObject( metadataObj:Object ):Object {
		metadataObj.copyCount 	= _copyCount;
		metadataObj.modify		= _modify;
		metadataObj.templateGuid= _templateGuid;
		metadataObj.creator		= _creator;
		metadataObj.created		= _created;
		metadataObj.binding		= _binding;
		return metadataObj;
	}
}
}
