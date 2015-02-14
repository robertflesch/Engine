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

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectModel extends ObjectInfo 
{
	protected var _guid:String 				= null;
	public function get guid():String 						{ return _guid; }
	public function set guid(value:String):void 			{ _guid = value; }
	
	public function ObjectModel( $guid:String ):void {
		super( ObjectInfo.OBJECTINFO_MODEL );
		_guid = $guid;
	}
	
	override public function asInventoryString():String {
		return String( _objectType + ";" + _guid );
	}
	
	override public function fromInventoryString( $data:String ): ObjectInfo {
		var values:Array = $data.split(";");
		if ( values.length != 2 ) {
			Log.out( "ObjectModel.fromInventoryString - not equal to 2 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		_objectType = values[0];
		_guid = values[1];
		return this;
	}

	override public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
		_guid	= "";
	}
	
}
}