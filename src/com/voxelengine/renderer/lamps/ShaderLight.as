/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.lamps {

import flash.geom.Vector3D;
	
public class ShaderLight {
	// R, G, B, A
	private var _position:Vector3D = new Vector3D();
	public function get position():Vector3D { return _position; }
	public function set position(value:Vector3D):void { _position = value; }
	public var color:Vector3D = new Vector3D( 1, 1, 1, 1 );
	public var endDistance:Number = 400;
	public var nearDistance:Number = 1;
	
	public function update():void
	{
	}

}
}

