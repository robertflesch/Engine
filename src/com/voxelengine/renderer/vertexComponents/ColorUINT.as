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
	
	import com.voxelengine.utils.ColorUtils;

public class ColorUINT extends VertexComponent {

	private var 	_ABGR:uint;
	
	// don’t forget that AGAL textures are written in BGRA not ARGB! You will have to set the endian of the used ByteArray properly like this:
	// byteArray.endian = Endian.LITTLE_ENDIAN;		
	public function ColorUINT( $RGBA:uint ):void {
		super( Context3DVertexBufferFormat.BYTES_4, 1 );
		_ABGR = ColorUtils.convertRGBAToABGR( $RGBA );
	}
	
	override public function setUint( $RGBA:uint ):void {
		_ABGR = ColorUtils.convertRGBAToABGR( $RGBA );
	}

	override public function writeToByteArray( $ba:ByteArray ):void {
		$ba.writeUnsignedInt( _ABGR );
	}
	
	public function toString():String
	{
		var str:String = _ABGR.toString(16);
		var hex:String = ("0x00000000").substr(2,8 - str.length) + str;
		return hex;
	}
	
}
}

