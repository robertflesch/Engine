/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.oxel
{

import flash.geom.Vector3D;
import com.voxelengine.Globals;

public class GrainCursor
{
	protected var _gx:uint = 0;
	protected var _gy:uint = 0;
	protected var _gz:uint = 0;
	protected var _data:uint = 0;

	private static var _s_v3:Vector3D = new Vector3D;
	private static var _s_gc:GrainCursor = new GrainCursor();	
	private static const AXES:Vector.<int> = new <int>[0,1,2];


	[inline]
	public function get grain( ):uint { return _data & 0x0000ffff; }
//	public function set grain( val:uint ):void { _data &= 0xffff0000; _data |= val; }
	[inline]
	public function set grain( val:uint ):void 
	{ 
		if ( bound < val )
			throw new Error( "GrainCursor.grain - trying to set grain to larger size then bound, or negative. new value:" + val );
		_data &= 0xffff0000; 
		_data |= val; 
	}


	[inline]
	public function get bound():uint { return (_data & 0xffff0000)>>16; }
	[inline]
	public function set bound(val:uint):void { _data &= 0x0000ffff; _data |= val << 16; }
	
	[inline]
	public function get grainX( ):uint { return _gx; }
	[inline]
	public function set grainX( val:uint ):void { _gx = val; }
	[inline]
	public function get grainY( ):uint { return _gy; }
	[inline]
	public function set grainY( val:uint ):void { _gy = val; }
	[inline]
	public function get grainZ( ):uint { return _gz; }
	[inline]
	public function set grainZ( val:uint ):void { _gz = val; }


	////////////////////////////////////////////////////////////////////
	// Static functions
	////////////////////////////////////////////////////////////////////

	[inline]
	public static function two_to_the_g( g:uint ):uint {
		// 2 raised to the power of g
		// 2^8 = 256
		return (1 << g);
	}

	[inline]
	public static function two_to_the_g_minus_1( g:uint ):uint {
		// 2 raised to the power of g minus 1
		// 2^8-1 = 255
		return ((1 << g) - 1);
	}
	
	[inline]
	public static function get_the_g0_size_for_grain( g:uint ):uint {
		// the size of any grain g in g0 units is:
		// 2 raised to the power of g
		return two_to_the_g(g);
	}
	
	[inline]
	public static function get_the_g0_edge_for_grain( g:uint ):uint {
		// the edge of any grain g in g0 units is:
		// 2 raised to the power of g - 1
		return two_to_the_g_minus_1(g);
	}

	[inline]
	public static function oxelSizeFromMeters( $meters:uint ):uint {
		if ( 1/16 == $meters )
			return 0;
		else if ( 1/8 == $meters )
			return 1;
		else if ( 1/4 == $meters )
			return 2;
		else if ( 1/2 == $meters )
			return 3;
		else if ( 1 == $meters )
			return 4;
		else if ( 2 == $meters )
			return 5;
		else if ( 4 == $meters )
			return 6;
		else if ( 8 == $meters )
			return 7;
		else if ( 16 == $meters )
			return 8;
		else if ( 32 == $meters )
			return 9;
		else if ( 64 == $meters )
			return 10;
		else if ( 128 == $meters )
			return 11;
		else if ( 256 == $meters )
			return 12;
		else if ( 512 == $meters )
			return 13;
		else if ( 1024 == $meters )
			return 14;
		else if ( 2048 == $meters )
			return 15;
		else if ( 4096 == $meters )
			return 16;

		return 17;
	}

	////////////////////////////////////////////////////////////////////
	// Member functions
	////////////////////////////////////////////////////////////////////
	
	public function GrainCursor( gx:uint=0, gy:uint=0, gz:uint=0, g:uint=0 ) {
		// keeps you from creating root...
		//if ( g >= s_max_grain ) {
			//trace("GrainCursor - ERROR - grain is over max grain size, desired: " + g + " max: " + s_max_grain );
			//g = s_max_grain - 1;
		//}
		_gx = gx;
		_gy = gy;
		_gz = gz;
		grain = g;
	}

	public function toObject():Object {
		var obj:Object = {};
		obj.gx = _gx;
		obj.gy = _gy;
		obj.gz = _gz;
		obj.grain = grain;
		obj.bound = bound;
		return obj;
	}

	public function fromObject( $obj:Object ):void {
		_gx = $obj.gx;
		_gy = $obj.gy;
		_gz = $obj.gz;
		bound = $obj.bound;
		grain = $obj.grain;
	}

	[inline]
	public static function roundToInt( x:Number, y:Number, z:Number, gct:GrainCursor ):void
	{
		// This is where it intersects with a grain 0
		gct.grainX = int( x );
		gct.grainY = int( y );
		gct.grainZ = int( z );
	}
	
	[inline]
	public static function getGrainFromPoint( x:Number, y:Number, z:Number, gct:GrainCursor, desiredGrain:int ):Boolean
	{
		// This is where it intersects with a grain 0
		gct.grainX = int( x );
		gct.grainY = int( y );
		gct.grainZ = int( z );
		gct.grain = 0;
		return gct.become_ancestor( desiredGrain );
	}

	[inline]
	public function getGrainFromVector( $pos:Vector3D, $desiredGrain:int ):Boolean
	{
		// This is where it intersects with a grain 0
		grainX = int( $pos.x );
		grainY = int( $pos.y );
		grainZ = int( $pos.z );
		grain = 0;
		return become_ancestor( $desiredGrain );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// http://stackoverflow.com/questions/3106666/intersection-of-line-segment-with-axis-aligned-box-in-c-sharp
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	[inline]
	private static function getCoordinate(  vector:Vector3D,  axis:int ):Number
	{
		switch (axis)
		{
			case 0:
				return vector.x;
			case 1:
				return vector.y;
			case 2:
				return vector.z;
			default:
				throw new Error("GrainCursor.GetCoordinate - Axis Value not found");
		}
	}	
	
	[inline]
	private static function setCoordinate(  vector:Vector3D,  axis:int,  adjustment:Number ):void
	{
		switch (axis)
		{
			case 0:
				vector.x -= adjustment;
				break;
			case 1:
				vector.y -= adjustment;
				break;
			case 2:
				vector.z -= adjustment;
				break;
			default:
				throw new Error("GrainCursor.SetCoordinate - Axis Value not found");
		}
	}	
	
	[inline]
	private function roundNumber( numIn:Number, decimalPlaces:int ):Number 
	{
		var nExp:int = Math.pow(10,decimalPlaces) ;
		return Math.round(numIn * nExp) / nExp;
	} 
	
	[inline]
	public function roundVector( v:Vector3D, places:int = 4 ):void
	{
		v.x = roundNumber(v.x,places);
		v.y = roundNumber(v.y,places);
		v.z = roundNumber(v.z,places);
		
		//return v;
	}
	

	[inline]
	public function childId():uint {
		var x:uint = grainX % 2; // ?? grainX >> (grain - 1);
		var y:uint = grainY % 2;
		var z:uint = grainZ % 2;
		
		// This number scheme is back asswards!
		var c:uint = 0;
		if ( z ) c += 4;
		if ( y ) c += 2;
		if ( x ) c += 1;
		
		return c;
	}
	
	[inline]
	public function child_inc():void {
		if ( !move_posx() )
		{
			set_values( 0, grainY, grainZ, grain );
			if ( !move_posz() )
			{
				set_values( 0, grainY, 0, grain );
				if ( !move_posy() )
					return;
			}
		}
	}
	
	[inline]
	public function reset():void
	{
		_gx = 0;
		_gy = 0;
		_gz = 0;
		_data = 0;
	}

	[inline]
	public function size():uint { return get_the_g0_size_for_grain(grain); }

	[inline]
	public function getModelX():uint { return _gx << grain; }
	[inline]
	public function getModelY():uint { return _gy << grain; }
	[inline]
	public function getModelZ():uint { return _gz << grain; }

	public function getModelVector():Vector3D
	{
		return new Vector3D( getModelX(), getModelY(), getModelZ() );
	}
	
	public function copyFrom( $gc:GrainCursor ):void
	{
		_gx = $gc._gx;
		_gy = $gc._gy;
		_gz = $gc._gz;
		_data = $gc._data;
	}



	[inline]
	public function g0_edgeval():uint
	{
		/*
				 max coord in g0 space
			---------------------------------------
			   7    F    F    F    F    F    F    F
			0111 1111 1111 1111 1111 1111 1111 1111
			---------------------------------------
		*/
		return get_the_g0_edge_for_grain( bound );
	}
	
	[inline]
	public function gn_edgeval( g:uint ):uint
	{
		/*
			example for g=7 and max grain 30
			
				g7 edge value
			---------------------------------------
			   7    F    F    F    F    F    F    F
			0000 0000 1111 1111 1111 1111 1111 1111
			---------------------------------------
		*/
		return (g0_edgeval() >> g);
	}
	
	[inline]
	public function edgeval():uint
	{
		// need to know the edge coord for this grain
		return gn_edgeval(grain );
	}

	[inline]
	public function is_oob( val:uint ):Boolean
	{
		// the edgeval is in bounds
		return ( val > edgeval() );
	}

	[inline]
	public function is_inb( val:uint ):Boolean
	{
		//trace( "GrainCursor.is_inb val: " + val + " bg: " +bg + " edgeval( bg ): " + edgeval( bg ) );
		// the edgeval is in bounds
		return ( val <= edgeval() );
	}
	
	[inline]
	public function is_edge( val:uint ):Boolean
	{
		// the edgeval is in bounds
		return ( val == edgeval() );
	}
		
	[inline]
	public function become_ancestor( k:uint ):Boolean
	{
		//trace( "become_ancestor: - was \t" + this.toString() );
		_gx >>= k;
		_gy >>= k;
		_gz >>= k;

		if ( grain + k > bound ) 
		{
			trace( "GrainCursor.become_ancestor: - ERROR trying to make ancestor larger then bound grain: " + grain + " change: " + k + " bound: " + bound + " this: " + this.toString() );
			return false;
		}
		grain += k;

		//trace( "become_ancestor: - now \t" + this.toString() );
		return true;
	}

	[inline]
	public function become_decendant( k:uint ):Boolean {
		if ( grain - k < 0) 
		{ 
			trace( "GrainCursor.become_decendant - Error - trying to make a child of grain0" );
			return false; 
		} // null operation
		
		_gx <<= k;
		_gy <<= k;
		_gz <<= k;

		grain -= k;
		return true;
	}

	[inline]
	public function become_parent():void { become_ancestor(1); }

	// values from 0-7 specifies which child to become
	[inline]
	public function become_child( n:uint = 0 ):Boolean {
		//trace( "become_child: - was \t" + this.toString() );
		if (grain == 0) 
		{ 
			trace( "GrainCursor.become_child - Error - trying to make a child of grain0" );
			return false; 
		} // null operation
		
		_gx <<= 1;
		_gy <<= 1;
		_gz <<= 1;
		grain -= 1;

		if (n > 0)
		{
			_gx += ((n>>0)&1);
			_gy += ((n>>1)&1);
			_gz += ((n>>2)&1);
		}
		//trace( "become_child: - now \t" + this.toString() );
		return true;
	}
	
	[inline]
	public function get_ancestor( k:uint ):GrainCursor {
		_s_gc.copyFrom(this);
		_s_gc.become_ancestor( k );
		return _s_gc;
	}	

	[inline]
	public function is_inside( $gc:GrainCursor ):Boolean {
		///////////////////////////////
		// true if this inside gc
		///////////////////////////////
		
		// we cannot be inside of $gc if we are larger
		if (grain > $gc.grain) 		return false;
		if ( is_equal( $gc ) ) return true;
		
		_s_gc.copyFrom(this);
		_s_gc.become_ancestor( $gc.grain - _s_gc.grain );
		return $gc.is_equal(_s_gc);
	}
	
	[inline]
	public function is_point_inside( point:Vector3D ):Boolean {
		///////////////////////////////
		// true if this inside gc
		///////////////////////////////
		getGrainFromPoint( point.x, point.y, point.z, _s_gc, 0 );
		_s_gc.become_ancestor( grain - _s_gc.grain );
		return _s_gc.is_equal(this);
	}
	
	[inline]
	public function move( face:int ):Boolean {
		if ( Globals.POSX == face )
			return move_posx();
		else if ( Globals.NEGX == face )
			return move_negx();
		else if ( Globals.POSY == face )
			return move_posy();
		else if ( Globals.NEGY == face )
			return move_negy();
		else if ( Globals.POSZ == face )
			return move_posz();
		else if ( Globals.NEGZ == face )
			return move_negz();
			
		throw new Error( "GrainCursor.move - INVALID FACE" );
		return false;
	}
	
	[inline]
	public function move_posz():Boolean	{ 
		if (is_inb( _gz + 1 )) 
		{
			_gz += 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function move_negz():Boolean	{ 
		if (is_inb( _gz - 1 )) 
		{
			_gz -= 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function move_posx():Boolean	{ 
		if (is_inb( _gx + 1 )) 
		{
			_gx += 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function move_negx():Boolean	{ 
		if (is_inb( _gx - 1 )) 
		{
			_gx -= 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function move_posy():Boolean	{ 
		if (is_inb( _gy + 1 ))
		{
			_gy += 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function move_negy():Boolean	{ 
		if (is_inb( _gy - 1 ))
		{
			_gy -= 1; 
			return true;
		}
		return false;
	}
	
	[inline]
	public function is_equal( $gc:GrainCursor ):Boolean {
		//trace( "is_equal: g: " + grain + " = " + $gc.grain  + "  x: " + _gx + " = " + $gc._gx + "  y: "  + _gy + " = " + $gc._gy + "  z: "  + _gz + " = " + $gc._gz   );
		return ( grain == $gc.grain
			&& _gx == $gc._gx
			&& _gy == $gc._gy
			&& _gz == $gc._gz
		);
	}

	[inline]
	public function is_outside( $gc:GrainCursor ):Boolean {
		///////////////////////////////
		// true if this outside $gc
		///////////////////////////////
		return(is_inside( $gc )	== false
			&& $gc.is_inside( this )	== false
		);
	}

	public function toString():String { return " x: " + _gx + "\t y: " + _gy + "\t z: "  + _gz + "\t grain: " + grain + " (" + size() + ")" + " bound: " + bound; }
	public function toID():String { return ((String(_gx) + _gy) + _gz) + grain; }
	
	[inline]
	public function set_values( x:uint, y:uint, z:uint, g:uint ):GrainCursor {
		_gx = x;
		_gy = y;
		_gz = z;
		grain  = g;
		
		return this;
	}

	[inline]
	public function contains_g0_point( x:int, y:int, z:int ):Boolean {
		// return true if the parameter point (g0 units) is inside this grain
		return(_gx == (x >> grain)
			&& _gy == (y >> grain)
			&& _gz == (z >> grain)
		);
	}
	
	public function containsModelSpacePoint( point:Vector3D ):Boolean {
		// return true if the parameter point (g0 units) is inside this grain
		return(_gx == ( point.x >> grain)
			&& _gy == ( point.y >> grain)
			&& _gz == ( point.z >> grain)
		);
	}
	
	public function eval( $grain:int, $x:int, $y:int, $z:int ):Boolean {
		if ( grain == $grain && grainY == $y && grainX == $x && grainZ == $z )
			return true;
		else
			return false;
	}
	
	public function evalGC( $gc:GrainCursor ):Boolean {
		if ( grain == $gc.grain && grainY == $gc.grainY && grainX == $gc.grainX && grainZ == $gc.grainZ )
			return true;
		else
			return false;
	}
	
}
}