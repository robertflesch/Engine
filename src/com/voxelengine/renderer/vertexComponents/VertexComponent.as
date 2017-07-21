/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.vertexComponents {
	import flash.utils.ByteArray;

public class VertexComponent {
	protected var 	_type:String;
	protected var 	_size:uint;
	
	public function VertexComponent( $type:String, $size:uint ):void {
		_type = $type;
		_size = $size;
	}
	
	public function setNums( one:Number, two:Number, three:Number ):void {}
	public function setInts( one:int, two:int, three:int):void {}
	public function setUint(args:uint):void {}
	
	public function writeToByteArray( ba:ByteArray ):void {}
	
	[inline]
	final public function get type():String { return _type; }
	
	[inline]
	final public function get size():uint { return _size; }
}
}

