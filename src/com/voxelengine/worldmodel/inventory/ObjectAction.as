/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.ConsoleCommands;
import com.voxelengine.Log;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.worldmodel.weapons.Ammo;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectAction extends ObjectInfo 
{
	private var _thumbnail:String;
	private var _name:String;
	private var _callBackName:String;
	//private var _callBack:Function;
	private var _ammoName:String;
	private var _instanceGuid:String;
	public function get callBack():Function 				{ return FunctionRegistry.functionGet( _callBackName ); }
	public function get thumbnail():String { return _thumbnail; }
	public function get name():String  { return _name; }
	
	public function get instanceGuid():String { return _instanceGuid; }
	public function set instanceGuid(value:String):void { _instanceGuid = value; }
	
	public function get ammoName():String { return _ammoName; }
	public function set ammoName(value:String):void { _ammoName = value; }

	public function ObjectAction( $owner:BoxInventory, $callBackName:String, $thumbnail:String, $name:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_ACTION );
		_callBackName = $callBackName;
		//if ( "" != $callBackName )
		//	_callBack = FunctionRegistry.functionGet( $callBackName );
		_thumbnail = $thumbnail;
		_name = $name;
	}
	
	override public function backgroundTexture( size:int = 64 ):String { 
		if ( 64 == size )
			return thumbnail;
			
		return thumbnail;
	}
	
	override public function asInventoryString():String {
		
		return String( _objectType + ";" + _thumbnail + ";" + _name + ";" + _callBackName + ";" + _ammoName + ";" + _instanceGuid );
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId );
		var values:Array = $data.split(";");
		if ( values.length != 6 ) {
			Log.out( "ObjectAction.fromInventoryString - not equal to 6 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		_objectType = values[0];
		_thumbnail = values[1];
		_name = values[2];
		_callBackName = values[3];
		_ammoName = values[4];
		_instanceGuid = values[5];
		//_callBack = ;
		return this;
	}

	override public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
		_thumbnail	= "";
		_name	= "";
		_ammoName = "";
		_instanceGuid = "";
		_callBackName = null;
		//_callBack = null
	}
}
}