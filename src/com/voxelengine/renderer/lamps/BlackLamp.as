/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.lamps {

import flash.geom.Vector3D;
	
public class BlackLamp extends ShaderLight {
	
	public function BlackLamp() {
		color.setTo( 0, 0, 0 );
		endDistance = 10;
	}
}
}

