/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.vertexComponents {
	import flash.utils.ByteArray;
	import flash.display3D.Context3DVertexBufferFormat;

public class Normal extends VertexComponent {

	private var 	_nx:int;
	private var 	_ny:int;
	private var 	_nz:int;
	
	public function Normal( $nx:int, $ny:int, $nz:int ):void {
		super( Context3DVertexBufferFormat.FLOAT_3, 3 );
		_nx = $nx;
		_ny = $ny;
		_nz = $nz;
	}
	
	override  public function setInts( $one:int, $two:int, $three:int):void {
		_nx = $one;
		_ny = $two;
		_nz = $three;
	}
	
	override public function writeToByteArray( $ba:ByteArray ):void {
		$ba.writeInt( _nx );
		$ba.writeInt( _ny );
		$ba.writeInt( _nz );
	}
	
}
}

