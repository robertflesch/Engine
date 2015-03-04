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
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.GUI.inventory.BoxInventory;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectTool extends ObjectInfo 
{
	private var _thumbnail:String;
	private var _name:String;
	private var _guid:String;
	private var _callBackName:String;
	private var _callBack:Function 		= null;
	public function get callBack():Function 				{ return _callBack; }
	public function get thumbnail():String { return _thumbnail; }
	public function get name():String  { return _name; }

	public function ObjectTool( $owner:BoxInventory, $guid:String, $callBackName:String, $thumbnail:String, $name:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_TOOL );
		_guid = $guid;
		_callBackName = $callBackName;
		if ( "" != $callBackName )
			_callBack = FunctionRegistry.functionGet( $callBackName );
		_thumbnail = $thumbnail;
		_name = $name;
	}
	
	override public function asInventoryString():String {
		
		return String( _objectType + ";" + _thumbnail + ";" + _name + ";" + _callBackName + ";" + _guid );
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId );
		var values:Array = $data.split(";");
		if ( values.length != 5 ) {
			Log.out( "ObjectTool.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		_objectType = values[0];
		_thumbnail = values[1];
		_name = values[2];
		_callBackName = values[3];
		_guid = values[4];
		_callBack = FunctionRegistry.functionGet( _callBackName );
		return this;
	}

	override public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
		_thumbnail	= "";
		_name	= "";
		_guid 	= "";
		_callBackName = null;
		_callBack = null
	}
}
}