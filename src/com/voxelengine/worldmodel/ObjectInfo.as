/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.worldmodel.models.MetadataManager;
import flash.utils.ByteArray;
import com.voxelengine.Log;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of inventory items in memory and persistance
 */
public class ObjectInfo 
{
	static public const OBJECTINFO_INVALID:int = 0;
	static public const OBJECTINFO_EMPTY:int = 1;
	static public const OBJECTINFO_VOXEL:int = 2;
	static public const OBJECTINFO_MODEL:int = 3;
	static public const OBJECTINFO_ACTION:int = 4;
	static public const OBJECTINFO_GRAIN:int = 5;
	static public const OBJECTINFO_TOOL:int = 6;
	
	protected var _objectType:int 			= OBJECTINFO_INVALID;
	
	public function get objectType():int 					{ return _objectType; }
	
	public function ObjectInfo( $objectType:int ):void {
		_objectType = $objectType;
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray 	{ return $ba; }
	public function fromByteArray( $ba:ByteArray ):ByteArray{ return $ba; }
	
	public function asInventoryString():String {
		return String( _objectType );
	}

	public function fromInventoryString( $data:String ): ObjectInfo {
		var values:Array = $data.split(";");
		if ( values.length != 1 ) {
			Log.out( "TypeInfo.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		return this;
	}
	
	public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
	}
}

}