/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import flash.utils.ByteArray;

/**
 * ...
 * @author ...
 */
public class ObjectInfo 
{
	static public const OBJECTINFO_INVALID:int = 0;
	static public const OBJECTINFO_VOXEL:int = 1;
	static public const OBJECTINFO_MODEL:int = 2;
	static public const OBJECTINFO_ACTION:int = 3;
	static public const OBJECTINFO_GRAIN:int = 4;
	
	protected var _image:String				= "grey64.png";
	protected var _name:String 				= "INVALID";
	protected var _guid:String 				= "INVALID";
	protected var _objectType:int 			= OBJECTINFO_INVALID;
	
	public function ObjectInfo( $type:int, $guid:String ):void { }
	
	public function get image():String 
	{
		return _image;
	}
	
	public function set image(value:String):void 
	{
		_image = value;
	}
	
	public function get name():String 
	{
		return _name;
	}
	
	public function set name(value:String):void 
	{
		_name = value;
	}
	
	public function get guid():String 
	{
		return _guid;
	}
	
	public function set guid(value:String):void 
	{
		_guid = value;
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray {
		// TODO I dont like that I have to reencode this over and over again.
		// should just be able to use the reference object.
		$ba.writeInt( _objectType );
		$ba.writeUTF( _guid );
		//ba.writeUTF( _name );
		//ba.writeUTF( _image );
		return $ba;
	}
	
}

}