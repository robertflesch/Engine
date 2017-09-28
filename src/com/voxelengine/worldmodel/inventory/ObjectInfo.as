/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.worldmodel.TextureBank;

import flash.utils.ByteArray;
import com.voxelengine.Log;
import com.voxelengine.GUI.inventory.BoxInventory;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of inventory items in memory and persistance
 */
public class ObjectInfo 
{
	static public const DEFAULT_OBJECT_NAME:String = "Drag an item here to use it";
	static public const OBJECTINFO_INVALID:int = 0;
	static public const OBJECTINFO_EMPTY:int = 1;
	static public const OBJECTINFO_VOXEL:int = 2;
	static public const OBJECTINFO_MODEL:int = 3;
	static public const OBJECTINFO_ACTION:int = 4;
	static public const OBJECTINFO_GRAIN:int = 5;
	static public const OBJECTINFO_TOOL:int = 6;
	
	protected var _objectType:int 			= OBJECTINFO_INVALID;
	protected var _box:BoxInventory;
	protected var _slotId:int;
	protected var _backgroundTexture:String = TextureBank.BLANK_IMAGE;
    protected var _name:String;
    public function get name():String  { return _name; }

	
	public function get objectType():int 					{ return _objectType; }
	
	public function get box():BoxInventory { return _box; }
	public function set box(value:BoxInventory):void  { _box = value; }
	
	public function backgroundTexture( size:int = 64 ):String { 
		if ( 64 == size )
			return _backgroundTexture;

        return "blank128.png";
	}
	
	public function ObjectInfo( $owner:BoxInventory, $objectType:int, $name:String ):void
	{ 
		_box = $owner;
		_objectType = $objectType;
		_name = $name;
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray 	{ return $ba; }
	public function fromByteArray( $ba:ByteArray ):ByteArray{ return $ba; }
	
	public function asInventoryString():String {
		return String( _objectType );
	}

	public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		_slotId = $slotId;
		return this;
	}
	
	public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
	}
}

}