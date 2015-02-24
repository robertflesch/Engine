/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import playerio.DatabaseObject;
/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class VoxelModelData
{
	private var _guid:String			= "";
	private var _dbo:DatabaseObject;
	
	public function VoxelModelData( $guid:String, $dbo:DatabaseObject ) {
		_guid = $guid;
		_dbo = $dbo;
	}
	
	public function get guid():String 
	{
		return _guid;
	}
	
	public function get dbo():DatabaseObject 
	{
		return _dbo;
	}
	
	public function set dbo(value:DatabaseObject):void 
	{
		_dbo = value;
	}
}
}

