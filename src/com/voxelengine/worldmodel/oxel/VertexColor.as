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
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import com.voxelengine.utils.ColorUtils;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;

/**
 * ...
 * @author Robert Flesch
 */
public class VertexColor {
	
	/*
	 *           0,1,0  ___________ 1,1,0
	 *                /|          /|
	 *               / |   1,1,1 / |
	 *     ^  0,1,1 /__|________/  |   POSX ->
	 *     |       |   |        |  |
	 *    POSY     |   |________|__|
	 *             |  / 0,0,0   |  / 1,0,0
	 *             | /          | /
	 *             |/___________|/
	 *      POSZ   0,0,1        1,0,1
	 *        |
	 *        \/
	 */
	
	//private var _colors:Vector.<uint> = new Vector.<uint>;
	// http://jacksondunstan.com/articles/1288 could this be faster?
	private var _colors:Dictionary = new Dictionary(true);
	private var _changed:Boolean = true;
	private var _composite:uint;
	
	public function VertexColor( $lightID:uint, $colorAndBrightness:uint ) {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.VertexColor - INVALID $lightID = 0" );
		lightAdd( $lightID, $colorAndBrightness );
	}
	
	public function lightsCopy( $colors:Dictionary ):void {
		for (var lightID:String in $colors )
		{
			var color:uint = $colors[lightID];
			lightAdd( uint(lightID), color );
		}
	}
	
	public function lightAdd( $lightID:uint, $colorAndBrightness:uint ):void {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.colorAdd - INVALID $lightID = 0" );
		_changed = true;
		_colors[$lightID] = $colorAndBrightness;
	}
	
	public function lightCount():uint {
		var count:uint = 0;
		for (var lightID:String in _colors )
		{
			count++;
		}
		return count;
	}
	
	public function colors():Dictionary {
		return _colors;
	}
	
	public function lightGet( $lightID:uint ):uint {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.colorGet - INVALID $lightID = 0" );
		return _colors[$lightID];
	}
	
	public function lightHas( $lightID:uint ):Boolean {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.colorHas - INVALID $lightID = 0" );
		if ( null == _colors[$lightID] )
			return false;
		
		return true;
	}
	
	public function reset():void {
		_colors = new Dictionary(true);
		_changed = false;
		
		lightAdd( Lighting.DEFAULT_LIGHT_ID, Lighting.DEFAULT_COLOR );
		//attnSet( Lighting.DEFAULT_LIGHT_ID, Lighting.DEFAULT_BASE_ATTEN );
	}
	
	public function attnGet( $lightID:uint ):uint {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.attnGet - INVALID $lightID = 0" );
			
		var attn:uint = _colors[$lightID] >>> 24;	
if ( 0 == attn )
	throw new Error( "VertexColor.attnSet - attn = 0" );
		return attn;
	}
	
	public function attnSet( $lightID:uint, $attn:uint ):void {
			//Log.out( "VertexColor.attnSet - lightID == 1, !!!" );
if ( 0 == $lightID )
	throw new Error( "VertexColor.attnSet - INVALID $lightID = 0" );
if ( 0 == $attn || 255 < $attn ) {
	$attn = Lighting.defaultBaseLightIllumination;
	throw new Error( "VertexColor.attnSet - attn == 0, reseting" ); }
	
		var val:uint = _colors[$lightID];
		
if ( 0 == val )
	throw new Error( "VertexColor.attnSet - val == 0, Color defined" );
	
		val &= 0x00ffffff;
		val |= $attn << 24;
		_colors[$lightID] = val;
	}
	
	public function lightRemove( $lightID:uint ):void {
		if ( 0 == $lightID )
			throw new Error( "VertexColor.colorRemove - INVALID $lightID = 0" );
		_changed = true;
		// Does this remove the null entry from the dictonary?
		delete _colors[$lightID]; //removes the key
	}
	
	// this returns a composite color made of default color plus any additional colors
//	public function lightGetComposite():uint {
//		if ( false == _changed )
//			return _composite;
//
//		_composite = 0;
//		for each ( var color:uint in _colors ) {
//			_composite = ColorUtils.testCombineARGB( _composite, color );
//		}
//
//		_changed = false;
//		return _composite;
//	}
	
} // end of class VertexColor
} // end of package
