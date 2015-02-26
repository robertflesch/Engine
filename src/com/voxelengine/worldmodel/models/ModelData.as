/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
import playerio.DatabaseObject;
/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class ModelData
{
	private var _guid:String			= "";
	private var _dbo:DatabaseObject;
	private var _ba:ByteArray;
	
	public function ModelData( $guid:String, $dbo:DatabaseObject, $ba:ByteArray = null ) {
		_guid = $guid;
		_dbo = $dbo;
		_ba = $ba;
	}
	
	public function get guid():String 
	{
		return _guid;
	}
	
	public function get ba():ByteArray 
	{
		return _ba;
	}
	
	public function get dbo():DatabaseObject 
	{
		return _dbo;
	}
	
	public function set ba(value:ByteArray):void 
	{
		_ba = value;
	}
}
}

