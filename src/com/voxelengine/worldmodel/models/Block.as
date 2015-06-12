/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.Dictionary;
	
import com.voxelengine.Log;
import com.voxelengine.Globals;

public class Block
{
	private var _blocks:Dictionary = new Dictionary(true);
	
	public function has( $guid:String ):Boolean {
		if ( null == _blocks[$guid] || false == _blocks[$guid] )
			return false;
		return true;	
	}
	
	public function add( $guid:String ):void {
		if ( null == _blocks[$guid] || false == _blocks[$guid] )
			_blocks[$guid] = true;
	}
	
	public function clear( $guid:String ):void {
		if ( _blocks[$guid] )
			_blocks[$guid] = false;
	}
}
}