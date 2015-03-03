/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.Log;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.GUI.inventory.BoxInventory;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectVoxel extends ObjectInfo 
{
	private var _typeId:int;
	public function get type():int { return _typeId; }

	public function ObjectVoxel( $owner:BoxInventory, $typeId:int ):void {
		super( $owner, ObjectInfo.OBJECTINFO_VOXEL );
		_typeId = $typeId;
	}
	
	override public function asInventoryString():String {
		return _objectType + ";" + _typeId;
	}
	
	override public function fromInventoryString( $data:String ): ObjectInfo {
		var values:Array = $data.split(";");
		if ( values.length != 2 ) {
			Log.out( "TypeInfo.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			_objectType = ObjectInfo.OBJECTINFO_VOXEL;
			_typeId = TypeInfo.RED;
			return this;
		}
		_objectType = ObjectInfo.OBJECTINFO_VOXEL;
		_typeId = values[1];
		
		return this;
	}

	override public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_VOXEL;
		_typeId = TypeInfo.RED;
	}
	
}
}