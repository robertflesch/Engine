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
import com.voxelengine.GUI.inventory.BoxInventory;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectGrain extends ObjectInfo 
{
	private var _image:String	= "";
	private var _name:String	= "";
	
	public function ObjectGrain( $owner:BoxInventory, $name:String, $image:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_GRAIN );
		_image = $image;
		_name = $name;
	}
	
	public function get image():String 
	{
		return _image;
	}
	
	public function get name():String 
	{
		return _name;
	}
}

}