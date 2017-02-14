/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.vertexComponents {
	import flash.utils.ByteArray;
	import flash.display3D.Context3DVertexBufferFormat;

public class UVScale extends VertexComponent {

	private var _u:Number;
	private var _v:Number;
	private var _scale:Number;
	
	public function UVScale( $u:Number, $v:Number, $scale:Number ):void {
		super( Context3DVertexBufferFormat.FLOAT_3, 3 );
		_u = $u;
		_v = $v;
		_scale = $scale;
	}
	
	override public function setNums( $one:Number, $two:Number, $three:Number ):void {
		_u = $one;
		_v = $two;
		_scale = $three;
	}

	override public function writeToByteArray( $ba:ByteArray ):void {
		$ba.writeFloat( _u );
		$ba.writeFloat( _v );
		$ba.writeFloat( _scale );
	}
}
}

