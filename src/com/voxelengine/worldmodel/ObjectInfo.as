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
import com.voxelengine.Log;

/**
 * ...
 * @author ...
 */
public class ObjectInfo 
{
	static public const OBJECTINFO_INVALID:int = 0;
	static public const OBJECTINFO_EMPTY:int = 1;
	static public const OBJECTINFO_VOXEL:int = 2;
	static public const OBJECTINFO_MODEL:int = 3;
	static public const OBJECTINFO_ACTION:int = 4;
	static public const OBJECTINFO_GRAIN:int = 5;
	
	protected var _image:String				= "blank.png";
	protected var _name:String 				= "Empty";
	protected var _guid:String 				= "INVALID";
	protected var _objectType:int 			= OBJECTINFO_INVALID;
	
	public function ObjectInfo( $type:int, $guid:String ):void {
		_objectType = $type;
		_guid = $guid;
	}
	
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
	
	public function get objectType():int 
	{
		return _objectType;
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray {
		// no additional byte data
		return $ba;
	}
	
	public function fromByteArray( $ba:ByteArray ):ByteArray {
		// no additional byte data
		return $ba;
	}
	
	public function asInventoryString():String {
		return _objectType + ";" + _guid + ";" + _image + ";" + _name;
	}
	
	public function fromInventoryString( $data:String ): ObjectInfo {
		var values:Array = $data.split(";");
		if ( values.length != 4 ) {
			Log.out( "TypeInfo.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			_objectType = ObjectInfo.OBJECTINFO_EMPTY;
			_guid = "";
			_image = "invalid.png";
			_name = "LoadingError";
			return this;
		}
		_objectType = ObjectInfo.OBJECTINFO_MODEL;
		_guid = values[1];
		_image = values[2];
		_name = values[3];
		
		return this;
	}
	
	
}

}