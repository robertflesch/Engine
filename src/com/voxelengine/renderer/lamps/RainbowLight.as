/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.lamps {

import flash.geom.Vector3D;
	
public class RainbowLight extends ShaderLight {
	
	private var _phase:Number = 0;
	
	public function RainbowLight():void {
		color.setTo( 1, 1, 1 );
	}
	
	override public function update():void
	{
		var frequency:Number = 2.4;
		color.x = Math.max( 0, Math.sin( frequency + 2 + _phase ) );
		color.y = Math.max( 0, Math.sin( frequency + _phase ) );
		color.z = Math.max( 0, Math.sin( frequency + 4 + _phase ) );
		 _phase += 0.03;
	}
}
}

