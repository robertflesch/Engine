/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.geom.Vector3D;

public class CameraLocation
{
	static public const FIRST_PERSON:int = 0;
	static public const BACK:int = 1;
	static public const BACK_TILTED:int = 2;
	static public const LOOK_DOWN:int = 3;

	private var _position:Vector3D = null;
	public function get position():Vector3D { return _position; }
	public function set position(value:Vector3D):void { _position = value; }

	private var _rotation:Vector3D = null;
	public function get rotation():Vector3D { return _rotation; }
	public function rotationSetTo( $x:Number, $y:Number, $z:Number ):void {
        //trace( "CameraLocation.rotationSetTo: " + _rotation + "  $x: " + $x + "  $y: " + $y + "  $z: " + $z );
		_rotation.setTo( $x, $y, $z )
	}

	private var _toolBarVisible:Boolean = false;
	public function get toolBarVisible():Boolean { return _toolBarVisible; }

	public function CameraLocation( $toolBarVisible:Boolean, x:int, y:int, z:int, roll:Number = 0, yaw:Number = 0, pitch:Number = 0 ):void {
		_toolBarVisible = $toolBarVisible;
		_position = new Vector3D( x, y, z );
		_rotation = new Vector3D( roll, yaw, pitch );
	}

}
}

