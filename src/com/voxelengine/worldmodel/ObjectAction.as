/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.Log;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectAction extends ObjectInfo 
{
	private var _image:String;
	private var _name:String;
	private var _callBackName:String;
	private var _callBack:Function 		= null;
	public function get callBack():Function 				{ return _callBack; }
	public function get image():String { return _image; }
	public function get name():String  { return _name; }

	public function ObjectAction( $callBackName:String, $image:String, $name:String ):void {
		super( ObjectInfo.OBJECTINFO_ACTION );
		_callBackName = $callBackName;
		if ( "" != $callBackName )
			_callBack = FunctionRegistry.functionGet( $callBackName );
		_image = $image;
		_name = $name;
	}
	
	override public function asInventoryString():String {
		
		return String( _objectType + ";" + _image + ";" + _name + ";" + _callBackName );
	}
	
	override public function fromInventoryString( $data:String ): ObjectInfo {
		var values:Array = $data.split(";");
		if ( values.length != 4 ) {
			Log.out( "ObjectAction.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		_objectType = values[0];
		_image = values[1];
		_name = values[2];
		_callBackName = values[3];
		_callBack = FunctionRegistry.functionGet( _callBackName );
		return this;
	}

	override public function reset():void {
		_objectType = ObjectInfo.OBJECTINFO_EMPTY;
		_image	= "";
		_name	= "";
		_callBackName = null;
		_callBack = null
	}
}
}