/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
import com.voxelengine.worldmodel.Light;
import com.voxelengine.worldmodel.models.types.Avatar;

import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.pools.LightInfoPool;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.utils.ColorUtils;
	
public class Lighting  {
	
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
	public static const DEFAULT_COLOR:uint = 0x00ffffff;

	public static const AMBIENT_ADD:Boolean = true;
	public static const AMBIENT_REMOVE:Boolean = false;

	public static const MAX_LIGHT_LEVEL:uint = 0xff;
	public static const DEFAULT_LIGHT_ID:uint = 1;
	public static const DEFAULT_BRIGHT_LIGHT_ID:uint = 2;
	public static const DEFAULT_ATTN:uint = 0x10;
	public static const DEFAULT_ILLUMINATION:uint = 0x33;

	// How much light falls off per meter for this material
	private static var _defaultBaseLightAttn:uint = 0x33; // out of 255
	// The default illumination level for this object.
	private static var _defaultBaseLightIllumination:uint = 0x33; // out of 255

	private static const CORNER_RESET_VAL:uint = 0;
	private static const CORNER_BUMP_VAL:uint = 1;

	private static var _s_eaoEnabled:Boolean = false;
	static public function get eaoEnabled():Boolean { return _s_eaoEnabled; }
	static public function set eaoEnabled(value:Boolean):void  { _s_eaoEnabled = value; }
	static public function get defaultBaseLightAttn():uint { return _defaultBaseLightAttn; }
//	static public function set defaultBaseLightAttn(value:uint):void  { _defaultBaseLightAttn = value; }

	static public function get defaultBaseLightIllumination():uint { return _defaultBaseLightIllumination; }
//	static public function set defaultBaseLightIllumination(value:uint):void  { _defaultBaseLightIllumination = value; }

//	public static function defaultLightIlluminationSetter():uint {
//		var temp:uint = _defaultBaseLightIllumination;
//		temp = temp | (_defaultBaseLightIllumination << 8);
//		temp = temp | (_defaultBaseLightIllumination << 16);
//		temp = temp | (_defaultBaseLightIllumination << 24);
//		return temp;
//	}
	
	static public const B000:uint = 0;
	static public const B001:uint = 1;
	static public const B100:uint = 2;
	static public const B101:uint = 3;
	static public const B010:uint = 4;
	static public const B011:uint = 5;
	static public const B110:uint = 6;
	static public const B111:uint = 7;
	
	// Ambient occlusion needs per face data, and for per face I need to store per face.
	// the choice is 0, 1, 2, so I need 2 bits of data to support that. 6 faces * 4 verts * 2 bits = 48 bits, 2 uints
	private var _lowerAmbient:uint;
	private var _higherAmbient:uint;
	public function get ambientHas():uint { return (_lowerAmbient || _higherAmbient ); }

	public function get posX100():uint { return ((_lowerAmbient  & 0x00000003)); }
	public function get posX101():uint { return ((_lowerAmbient  & 0x0000000c) >> 2 ); }
	public function get posX110():uint { return ((_lowerAmbient  & 0x00000030) >> 4 ); }
	public function get posX111():uint { return ((_lowerAmbient  & 0x000000c0) >> 6 ); }
	public function get negX000():uint { return ((_lowerAmbient  & 0x00000300) >> 8 ); }
	public function get negX001():uint { return ((_lowerAmbient  & 0x00000c00) >> 10 ); }
	public function get negX010():uint { return ((_lowerAmbient  & 0x00003000) >> 12 ); }
	public function get negX011():uint { return ((_lowerAmbient  & 0x0000c000) >> 14 ); }
	
	public function get posY010():uint { return ((_lowerAmbient  & 0x00030000) >> 16 ); }
	public function get posY011():uint { return ((_lowerAmbient  & 0x000c0000) >> 18 ); }
	public function get posY110():uint { return ((_lowerAmbient  & 0x00300000) >> 20 ); }
	public function get posY111():uint { return ((_lowerAmbient  & 0x00c00000) >> 22 ); }
	public function get negY000():uint { return ((_lowerAmbient  & 0x03000000) >> 24 ); }
	public function get negY001():uint { return ((_lowerAmbient  & 0x0c000000) >> 26 ); }
	public function get negY100():uint { return ((_lowerAmbient  & 0x30000000) >> 28 ); }
	public function get negY101():uint { return ((_lowerAmbient  & 0xc0000000) >>> 30 ); }

	public function get posZ001():uint { return ((_higherAmbient  & 0x00000003)); }
	public function get posZ011():uint { return ((_higherAmbient  & 0x0000000c) >> 2 ); }
	public function get posZ101():uint { return ((_higherAmbient  & 0x00000030) >> 4 ); }
	public function get posZ111():uint { return ((_higherAmbient  & 0x000000c0) >> 6 ); }
	public function get negZ000():uint { return ((_higherAmbient  & 0x00000300) >> 8 ); }
	public function get negZ010():uint { return ((_higherAmbient  & 0x00000c00) >> 10 ); }
	public function get negZ100():uint { return ((_higherAmbient  & 0x00003000) >> 12 ); }
	public function get negZ110():uint { return ((_higherAmbient  & 0x0000c000) >> 14 ); }
	
	public function get posX():uint { return ((_higherAmbient  & 0x00010000) >> 16 ); }
	public function get negX():uint { return ((_higherAmbient  & 0x00020000) >> 17 ); }
	public function get posY():uint { return ((_higherAmbient  & 0x00040000) >> 18 ); }
	public function get negY():uint { return ((_higherAmbient  & 0x00080000) >> 19 ); }
	public function get posZ():uint { return ((_higherAmbient  & 0x00100000) >> 20 ); }
	public function get negZ():uint { return ((_higherAmbient  & 0x00200000) >> 21 ); }

	public function set posX( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xfffeffff) | value << 16); }	
	public function set negX( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xfffdffff) | value << 17); }	
	public function set posY( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xfffbffff) | value << 18); }	
	public function set negY( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xfff7ffff) | value << 19); }	
	public function set posZ( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xffefffff) | value << 20); }	
	public function set negZ( value:uint ):void { _higherAmbient = ((_higherAmbient & 0xffdfffff) | value << 21); }	

	public function set posX100( value:uint ):void {
		// if we are setting the value of posX100 to ZERO, allow it here
		if ( 0 == value ) value = Math.max( posX100 - 1, 0 );
		// for any other number in value, we can only set posX100 to 1 or 2
		// depending on its neighbors
		else if ( 0 == posX100 ) value = 1;
		else if  ( 1 <= posX110 && 1 <= posX101 ) value = 2;
		// now take the number in value and put its bits into the bit holder
		_lowerAmbient = ((_lowerAmbient & 0xfffffffc) | value); }	
	public function set posX101( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posX101 - 1, 0 );
		else if ( 0 == posX101 ) value = 1;
		else if  ( 1 <= posX100 && 1 <= posX111 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfffffff3) | value << 2 ); }	
	public function set posX110( value:uint ):void {
		if ( 0 == value ) value = Math.max( posX110 - 1, 0 );
		else if ( 0 == posX110 ) value = 1;
		else if  ( 1 <= posX100 && 1 <= posX111 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xffffffcf) | value << 4 ); }	
	public function set posX111( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posX111 - 1, 0 );
		else if ( 0 == posX111 ) value = 1;
		else if  ( 1 <= posX101 && 1 <= posX110 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xffffff3f) | value << 6 ); }
	
	public function set negX000( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negX000 - 1, 0 );
		else if ( 0 == negX000 ) value = 1;
		else if  ( 1 <= negX010 && 1 <= negX001 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfffffcff) | value << 8 ); }
	public function set negX001( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negX001 - 1, 0 );
		else if ( 0 == negX001 ) value = 1;
		else if  ( 1 <= negX000 && 1 <= negX011 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfffff3ff) | value << 10 ); }
	public function set negX010( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negX010 - 1, 0 );
		else if ( 0 == negX010 ) value = 1;
		else if  ( 1 <= negX000 && 1 <= negX011 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xffffcfff) | value << 12 ); }
	public function set negX011( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negX011 - 1, 0 );
		else if ( 0 == negX011 ) value = 1;
		else if  ( 1 <= negX010 && 1 <= negX001 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xffff3fff) | value << 14 ); }
		
	public function set posY010( value:uint ):void {
		if ( 0 == value ) value = Math.max( posY010 - 1, 0 );
		else if ( 0 == posY010 ) value = 1;
		else if  ( 1 <= posY110 && 1 <= posY011 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfffcffff) | value << 16 ); }
	public function set posY011( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posY011 - 1, 0 );
		else if ( 0 == posY011 ) value = 1;
		else if  ( 1 <= posY010 && 1 <= posY111 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfff3ffff) | value << 18 ); }
	public function set posY110( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posY110 - 1, 0 );
		else if ( 0 == posY110 ) value = 1;
		else if  ( 1 <= posY010 && 1 <= posY111 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xffcfffff) | value << 20 ); }
	public function set posY111( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posY111 - 1, 0 );
		else if ( 0 == posY111 ) value = 1;
		else if  ( 1 <= posY110 && 1 <= posY011 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xff3fffff) | value << 22 ); }
	
	public function set negY000( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negY000 - 1, 0 );
		else if ( 0 == negY000 ) value = 1;
		else if  ( 1 <= negY100 && 1 <= negY001 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xfcffffff) | value << 24 ); }
	public function set negY001( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negY001 - 1, 0 );
		else if ( 0 == negY001 ) value = 1;
		else if  ( 1 <= negY000 && 1 <= negY101 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xf3ffffff) | value << 26 ); }
	public function set negY100( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negY100 - 1, 0 );
		else if ( 0 == negY100 ) value = 1;
		else if  ( 1 <= negY101 && 1 <= negY000 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0xcfffffff) | value << 28 ); }
	public function set negY101( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negY101 - 1, 0 );
		else if ( 0 == negY101 ) value = 1;
		else if  ( 1 <= negY100 && 1 <= negY001 ) value = 2;
		_lowerAmbient = ((_lowerAmbient & 0x3fffffff) | value << 30 ); }
		
	public function set posZ001( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posZ001 - 1, 0 );
		else if ( 0 == posZ001 ) value = 1;
		else if  ( 1 <= posZ011 && 1 <= posZ101 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xfffffffc) | value << 0 ); }
	public function set posZ011( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posZ011 - 1, 0 );
		else if ( 0 == posZ011 ) value = 1;
		else if  ( 1 <= posZ001 && 1 <= posZ111 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xfffffff3) | value << 2 ); }
	public function set posZ101( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posZ101 - 1, 0 );
		else if ( 0 == posZ101 ) value = 1;
		else if  ( 1 <= posZ001 && 1 <= posZ111 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xffffffcf) | value << 4 ); }
	public function set posZ111( value:uint ):void { 
		if ( 0 == value ) value = Math.max( posZ111 - 1, 0 );
		else if ( 0 == posZ111 ) value = 1;
		else if  ( 1 <= posZ101 && 1 <= posZ011 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xffffff3f) | value << 6 ); }
	
	public function set negZ000( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negZ000 - 1, 0 );
		else if ( 0 == negZ000 ) value = 1;
		else if  ( 1 <= negZ010 && 1 <= negZ100 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xfffffcff) | value << 8 ); }
	public function set negZ010( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negZ010 - 1, 0 );
		else if ( 0 == negZ010 ) value = 1;
		else if  ( 1 <= negZ000 && 1 <= negZ110 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xfffff3ff) | value << 10 ); }
	public function set negZ100( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negZ100 - 1, 0 );
		else if ( 0 == negZ100 ) value = 1;
		else if  ( 1 <= negZ000 && 1 <= negZ110 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xffffcfff) | value << 12 ); }
	public function set negZ110( value:uint ):void { 
		if ( 0 == value ) value = Math.max( negZ110 - 1, 0 );
		else if ( 0 == negZ110 ) value = 1;
		else if  ( 1 <= negZ010 && 1 <= negZ100 ) value = 2;
		_higherAmbient = ((_higherAmbient & 0xffff3fff) | value << 14 ); }
	
	// Just a convience value to prevent the recalculation of the color values unless needed
	private var _compositeColor:uint;

	private var _materialFallOffFactor:uint = Light.DEFAULT_FALLOFF_FACTOR; // Multiplier on the lights attn rate
	public function get materialFallOffFactor():uint { return _materialFallOffFactor; }
	public function set materialFallOffFactor( val:uint ):void { _materialFallOffFactor = val; }
	
	private var _lights:Vector.<LightInfo> = new Vector.<LightInfo>();
	public function lightCount():int { return _lights.length }
	
	private var _color:uint = 0xffffffff;
	public function get color():uint { return _color; }
	public function set color( val:uint ):void { _color = val; }
	
	//private function rnd( $val:uint ):uint { return int($val * 100) / 100; }
	
	public function Lighting():void {
		
		//add( DEFAULT_LIGHT_ID, DEFAULT_COLOR, Lighting.DEFAULT_ATTN, _defaultBaseLightAttn );
	}

	public function addFullBright():void {
		var li:LightInfo = LightInfoPool.poolGet();
		li.setInfo( Lighting.DEFAULT_BRIGHT_LIGHT_ID, Lighting.DEFAULT_COLOR, Lighting.DEFAULT_ATTN, Lighting.MAX_LIGHT_LEVEL );
		add( li );
	}

	public function ambientOcculsionHas():Boolean {
			
		return 0 < (_higherAmbient & 0x003f0000) ? true : false;
	}

	public function ambientOcculsionReset():void {
			
		_higherAmbient = _higherAmbient & 0xffd0ffff;
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray {

		$ba.writeUnsignedInt( _color );
		$ba.writeUnsignedInt( _lowerAmbient );
		$ba.writeUnsignedInt( _higherAmbient );

		// calculate how many lights this oxel is influcence by
		// dont count the region light which has ID 1
		var lightCount:uint;
		for ( var i:int = 0; i < _lights.length; i++ ) {
			if ( null != _lights[i] && _lights[i].ID != Lighting.DEFAULT_LIGHT_ID )
				lightCount++;
		}
		// now write the count of lights to the byte array
		$ba.writeByte( lightCount );

		//Log.out( "Lighting.toByteArray - \t\t\tcolor: " + _color.toString(16) );
		//Log.out( "Lighting.toByteArray - \t\tlowerAmbient: " + _lowerAmbient.toString(16));
		//Log.out( "Lighting.toByteArray - \t\thigherAmbient: " + _higherAmbient.toString(16) );
		//Log.out( "Lighting.toByteArray - \t\t\tlightCount: " + lightCount );

		// now for each light, write its contents to the byte array
		// dont save the region light which has ID 1
		for ( var j:int = 0; j < _lights.length; j++ ) {
			var li:LightInfo = _lights[j];
			if ( null != li  && _lights[j].ID != Lighting.DEFAULT_LIGHT_ID ) {
				$ba = li.toByteArray( $ba );
			}
		}
		return $ba;
	}

// TODO Maybe - Not sure what attnPerMeter should be here, that value is not persisted to the ivm.
	// However I dont know if it is ever used again, so what should I set it to?
	public function fromByteArray( $version:int, $ba:ByteArray, $attnPerMeter:uint = 0x10 ):ByteArray {
		var lightCount:int;
		var i:int;
		if ( Globals.VERSION_001 == $version || Globals.VERSION_002 == $version ) {
			// Old style, Just throw away this information.
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
			$ba.readInt();
		}
		else if ( Globals.VERSION_003 == $version ){
			// How many light do I need to read?
			lightCount = $ba.readByte();
			// Now read each light
			for ( i = 0; i < lightCount; i++ ) {
				_lights[i] = LightInfoPool.poolGet();
				_lights[i].fromByteArray( $ba );
			}
		}
		else if ( Globals.VERSION_004 == $version || Globals.VERSION_005 == $version ) {
			_lowerAmbient = $ba.readUnsignedInt();
			_higherAmbient = $ba.readUnsignedInt();
			lightCount = $ba.readByte();
			// Now read each light
			for ( i = 0; i < lightCount; i++ ) {
				_lights[i] = LightInfoPool.poolGet();
				_lights[i].fromByteArray( $ba );
			}
		}
		else if ( Globals.VERSION_006 <= $version ) {
			_color = $ba.readUnsignedInt();
			_lowerAmbient = $ba.readUnsignedInt();
			_higherAmbient = $ba.readUnsignedInt();
			lightCount = $ba.readByte();

			//Log.out( "Lighting.fromByteArray - \t\tcolor: \t\t" + _color.toString(16) );
			//Log.out( "Lighting.fromByteArray - \t\tlowerAmbient: \t" + _lowerAmbient.toString(16) );
			//Log.out( "Lighting.fromByteArray - \t\thigherAmbient: \t" + _higherAmbient.toString(16) );
			//Log.out( "Lighting.fromByteArray - \t\tlightCount: \t\t" + lightCount );

			//try {
				// Now read each light
				for (i = 0; i < lightCount; i++) {
					var light:Object = {};
					LightInfo.fromByteArrayEvaluator($ba, light);
					// The chunk lights should not be written to byte array, or read...
					if (Lighting.DEFAULT_LIGHT_ID != light.ID) {
						var li:LightInfo = LightInfoPool.poolGet();
						li.fromObject(light);
						_lights.push(li);
					}
				}
//			} catch ( e:Error ) {
//					Log.out( "Lighting.fromByteArray: ERROR: " + e.toString(), Log.ERROR, e );
//			}
		}
		else
			throw new Error( "Brightness.fromByteArray - unsupported version: " + $version );

		return $ba;
	}

	public function toString():String {
		var outputString:String = "";
		for ( var i:int = 0; i < _lights.length; i++ ) {
			var li:LightInfo = _lights[i];
			if ( null != li ) {
				outputString += "\tlight: " + i + "  " + li.toString();
			}
		}
		return outputString;
	}
	
	public function copyFrom( $b:Lighting ):void {
		
		// Copy all of the light data from the passed in Brightness
		for ( var i:int = 0; i < $b._lights.length; i++ ) {
			var sli:LightInfo = $b._lights[i];
			if ( null != sli ) { 
				if ( _lights.length <= i || (null == _lights[i]) ) {
					_lights[i] = LightInfoPool.poolGet();
				}
				_lights[i].copyFrom( sli );
			}
			else {
                if ( _lights[i] ){
                    LightInfoPool.poolReturn( _lights[i] );
                    _lights[i] = null;
                    _lights.slice(i, 1);
                }
            }
		}
	}
	
	public function setAll( $ID:uint, $attn:uint ):void	{
		
		var li:LightInfo =  lightGet( $ID );
		
		if ( null == li )
			throw new Error( "Brightness.setAll - light not defined" );
			
		if ( Lighting.MAX_LIGHT_LEVEL < $attn )
			throw new Error( "Brightness.setAll - attn too high" );

		li.attn = $attn;
	}
	
	public function valuesHas():Boolean	{

		for ( var i:int = 0; i < _lights.length; i++ ) {
			var li:LightInfo = _lights[i];
			if ( null != li ) {
				//if ( DEFAULT_BASE_LIGHT_LEVEL + DEFAULT_SIGMA < li.avg )
				if ( _defaultBaseLightAttn < li.avg )
					return true;
			}
		}
		
		return false;
	}
	
	public function valuesHasForFace( $ID:uint, $face:uint ):Boolean	{

		if ( !lightHas( $ID ) )
			return false;
			
		var li:LightInfo = lightGet( $ID );
		if ( null != li )
		{
			//const THRESHOLD:uint = DEFAULT_BASE_LIGHT_LEVEL + DEFAULT_SIGMA;
			// Sigma was giving me hard edges
			const THRESHOLD:uint = _defaultBaseLightAttn;
			if ( Globals.POSX == $face ) {
				
				if ( THRESHOLD < li.b100 ) { return true }
				if ( THRESHOLD < li.b110 ) { return true }
				if ( THRESHOLD < li.b111 ) { return true }
				if ( THRESHOLD < li.b101 ) { return true }
			}
			else if ( Globals.NEGX == $face ) {

				if ( THRESHOLD < li.b000 ) { return true }
				if ( THRESHOLD < li.b010 ) { return true }
				if ( THRESHOLD < li.b011 ) { return true }
				if ( THRESHOLD < li.b001 ) { return true }
			}
			else if ( Globals.POSY == $face ) {

				if ( THRESHOLD < li.b010 ) { return true }
				if ( THRESHOLD < li.b110 ) { return true }
				if ( THRESHOLD < li.b111 ) { return true }
				if ( THRESHOLD < li.b011 ) { return true }
			}
			else if ( Globals.NEGY == $face ) {

				if ( THRESHOLD < li.b000 ) { return true }
				if ( THRESHOLD < li.b100 ) { return true }
				if ( THRESHOLD < li.b101 ) { return true }
				if ( THRESHOLD < li.b001 ) { return true }
			}
			else if ( Globals.POSZ == $face ) {

				if ( THRESHOLD < li.b001 ) { return true }
				if ( THRESHOLD < li.b011 ) { return true }
				if ( THRESHOLD < li.b111 ) { return true }
				if ( THRESHOLD < li.b101 ) { return true }
			}
			else if ( Globals.NEGZ == $face ) {
				
				if ( THRESHOLD < li.b000 ) { return true }
				if ( THRESHOLD < li.b010 ) { return true }
				if ( THRESHOLD < li.b110 ) { return true }
				if ( THRESHOLD < li.b100 ) { return true }
			}
		}
		return false;
	}
	
	public function reset():Boolean {
		resetToAmbient();
		
		if ( _lowerAmbient ||  _higherAmbient ) {
			_lowerAmbient = 0;
			_higherAmbient = 0;
		}
		_compositeColor = 0;
		return true;
	}

	public function resetToAmbient():void {
		_lights = new Vector.<LightInfo>();
	}

	public function mergeChildren( $childID:uint, $b:Lighting, $grainUnits:uint, $hasAlpha:Boolean ):void {
		// There is a bug in here, since it is the first three lights that get added.
		// I should eval each child and see if its light level is higher then one of the current lights
		var childLightCount:uint = $b._lights.length;
		for ( var i:int = 0; i < childLightCount; i++ ) {
			var li:LightInfo = $b._lights[i];
			if ( null != li && _defaultBaseLightAttn < li.avg )
				childAdd( li.ID, $childID, $b, $grainUnits, $hasAlpha );
		}
	}
	
	public function childAdd( $ID:uint, $childID:uint, $cb:Lighting, $grainUnits:uint, $hasAlpha:Boolean ):void {	

		var sli:LightInfo =  $cb.lightGet( $ID );	
		if ( null == sli )
			return; // This is potential bug in process where child lights get 
			//throw new Error( "Brightness.childAdd - SOURCE light not defined" );
		if ( _defaultBaseLightAttn == sli.avg )
			return;
			
		// This is special case which needs to take into account attn
		var localattn:uint = materialFallOffFactor * sli.attn * $grainUnits / Avatar.UNITS_PER_METER;
		var sqrattn:Number =  Math.sqrt( 2 * (localattn * localattn) );
		var csqrattn:Number = Math.sqrt( (localattn * localattn) + (sqrattn * sqrattn) );

		var newLi:LightInfo = LightInfoPool.poolGet();
		newLi.setInfo( $ID, sli.color, sli.attn, sli.avg );
		if ( !add( newLi ) ) {
			LightInfoPool.poolReturn(newLi);
			return; // failed to add the light, This is a valid condition, if the light added is lower then the existing lights, it will not be added
		}
		var li:LightInfo =  lightGet( $ID );		
		
		// The corner that the child is in is always the most accurate data, everything else is a guess
		if ( 0 == $childID ) {
			li.b000 = sli.b000;
			if ( li.b001 < sli.b001 - localattn )  li.b001 = sli.b001 - localattn;
			if ( li.b100 < sli.b100 - localattn )  li.b100 = sli.b100 - localattn;
			if ( li.b010 < sli.b010 - localattn )  li.b010 = sli.b010 - localattn;
			if ( $hasAlpha ) {
				if ( li.b101 < sli.b101 - sqrattn )  	li.b101 = sli.b101 - sqrattn;
				if ( li.b011 < sli.b011 - sqrattn )  	li.b011 = sli.b011 - sqrattn;
				if ( li.b110 < sli.b110 - sqrattn )  	li.b110 = sli.b110 - sqrattn;
				if ( li.b111 < sli.b111 - csqrattn )  	li.b111 = sli.b111 - csqrattn;
			}
		}
		else if ( 1 == $childID ) {
			if ( li.b000 < sli.b000 - localattn )  		li.b000 = sli.b000 - localattn;
														li.b100 = sli.b100;
			if ( li.b101 < sli.b101 - localattn )  		li.b101 = sli.b101 - localattn;
			if ( li.b110 < sli.b110 - localattn )  		li.b110 = sli.b110 - localattn;

			if ( $hasAlpha ) {			
				if ( li.b001 < sli.b001 - sqrattn )  	li.b001 = sli.b001 - sqrattn;
				if ( li.b010 < sli.b010 - sqrattn )  	li.b010 = sli.b010 - sqrattn;
				if ( li.b011 < sli.b011 - csqrattn )  	li.b011 = sli.b011 - csqrattn;
				if ( li.b111 < sli.b111 - sqrattn )  	li.b111 = sli.b111 - sqrattn;
			}
		}
		else if ( 2 == $childID ) {
			if ( li.b000 < sli.b000 - localattn )  		li.b000 = sli.b000 - localattn;
														li.b010 = sli.b010;
			if ( li.b011 < sli.b011 - localattn )  		li.b011 = sli.b011 - localattn;
			if ( li.b110 < sli.b110 - localattn )  		li.b110 = sli.b110 - localattn;
			
			if ( $hasAlpha ) {			
				if ( li.b001 < sli.b001 - sqrattn )  	li.b001 = sli.b001 - sqrattn;
				if ( li.b100 < sli.b100 - sqrattn )  	li.b100 = sli.b100 - sqrattn;
				if ( li.b101 < sli.b101 - csqrattn )  	li.b101 = sli.b101 - csqrattn;
				if ( li.b111 < sli.b111 - sqrattn )  	li.b111 = sli.b111 - sqrattn;
			}
		}
		else if ( 3 == $childID ) {
			if ( li.b100 < sli.b100 - localattn )  		li.b100 = sli.b100 - localattn;
			if ( li.b010 < sli.b010 - localattn )  		li.b010 = sli.b010 - localattn;
														li.b110 = sli.b110;
			if ( li.b111 < sli.b111 - localattn )  		li.b111 = sli.b111 - localattn;
			       
			if ( $hasAlpha ) {			
				if ( li.b011 < sli.b011 - sqrattn )  	li.b011 = sli.b011 - sqrattn;
				if ( li.b101 < sli.b101 - sqrattn )  	li.b101 = sli.b101 - sqrattn;
				if ( li.b000 < sli.b000 - sqrattn )  	li.b000 = sli.b000 - sqrattn;
				if ( li.b001 < sli.b001 - csqrattn )  	li.b001 = sli.b001 - csqrattn;
			}
		}
		else if ( 4 == $childID ) {
			if ( li.b000 < sli.b000 - localattn )  		li.b000 = sli.b000 - localattn;
														li.b001 = sli.b001;
			if ( li.b011 < sli.b011 - localattn )  		li.b011 = sli.b011 - localattn;
			if ( li.b101 < sli.b101 - localattn ) 		li.b101 = sli.b101 - localattn;
			       
			if ( $hasAlpha ) {			
				if ( li.b100 < sli.b100 - sqrattn )  	li.b100 = sli.b100 - sqrattn;
				if ( li.b010 < sli.b010 - sqrattn )  	li.b010 = sli.b010 - sqrattn;
				if ( li.b110 < sli.b110 - csqrattn )  	li.b110 = sli.b110 - csqrattn;
				if ( li.b111 < sli.b111 - sqrattn )  	li.b111 = sli.b111 - sqrattn;
			}
		}
		else if ( 5 == $childID ) {
			if ( li.b001 < sli.b001 - localattn )  		li.b001 = sli.b001 - localattn;
			if ( li.b100 < sli.b100 - csqrattn )  		li.b100 = sli.b100 - localattn;
														li.b101 = sli.b101;
			if ( li.b111 < sli.b111 - localattn )  		li.b111 = sli.b111 - localattn;
			       
			if ( $hasAlpha ) {			
				if ( li.b000 < sli.b000 - sqrattn )  	li.b000 = sli.b000 - sqrattn;
				if ( li.b010 < sli.b010 - csqrattn )  	li.b010 = sli.b010 - csqrattn;
				if ( li.b011 < sli.b011 - sqrattn )  	li.b011 = sli.b011 - sqrattn;
				if ( li.b110 < sli.b110 - sqrattn )  	li.b110 = sli.b110 - sqrattn;
			}
		}
		else if ( 6 == $childID ) {
			if ( li.b010 < sli.b010 - localattn ) 		li.b010 = sli.b010 - localattn;
														li.b011 = sli.b011;		
			if ( li.b111 < sli.b111 - localattn ) 		li.b111 = sli.b111 - localattn;
			if ( li.b001 < sli.b001 - localattn ) 		li.b001 = sli.b001 - localattn;
			       
			if ( $hasAlpha ) {			
				if ( li.b000 < sli.b000 - sqrattn )  	li.b000 = sli.b000 - sqrattn;
				if ( li.b110 < sli.b110 - sqrattn )  	li.b110 = sli.b110 - sqrattn;
				if ( li.b100 < sli.b100 - csqrattn )  	li.b100 = sli.b100 - csqrattn;
				if ( li.b101 < sli.b101 - sqrattn )  	li.b101 = sli.b101 - sqrattn;
			}
		}
		else if ( 7 == $childID ) {
			if ( li.b011 < sli.b011 - localattn ) 		li.b011 = sli.b011 - localattn;
			if ( li.b110 < sli.b110 - localattn ) 		li.b110 = sli.b110 - localattn;
														li.b111 = sli.b111;		
			if ( li.b101 < sli.b101 - localattn ) 		li.b101 = sli.b101 - localattn;
			       
			if ( $hasAlpha ) {			
				if ( li.b000 < sli.b000 - csqrattn )  	li.b000 = sli.b000 - csqrattn;
				if ( li.b001 < sli.b001 - sqrattn )  	li.b001 = sli.b001 - sqrattn;
				if ( li.b100 < sli.b100 - sqrattn )  	li.b100 = sli.b100 - sqrattn;
				if ( li.b010 < sli.b010 - sqrattn )  	li.b010 = sli.b010 - sqrattn;
			}
		}
		
		if ( li.b000 < _defaultBaseLightAttn ) li.b000 = _defaultBaseLightAttn;
		if ( li.b001 < _defaultBaseLightAttn ) li.b001 = _defaultBaseLightAttn;
		if ( li.b010 < _defaultBaseLightAttn ) li.b010 = _defaultBaseLightAttn;
		if ( li.b011 < _defaultBaseLightAttn ) li.b011 = _defaultBaseLightAttn;
		if ( li.b100 < _defaultBaseLightAttn ) li.b100 = _defaultBaseLightAttn;
		if ( li.b101 < _defaultBaseLightAttn ) li.b101 = _defaultBaseLightAttn;
		if ( li.b110 < _defaultBaseLightAttn ) li.b110 = _defaultBaseLightAttn;
		if ( li.b111 < _defaultBaseLightAttn ) li.b111 = _defaultBaseLightAttn;
	}
	
	// creates a virtual brightness(light) the light from a parent to a child brightness with all lights
	public function childGetAllLights( $childID:int, $b:Lighting ):void {

		for ( var i:int = 0; i < _lights.length; i++ ) {
			var li:LightInfo = _lights[i];
			if ( null != li )
				childGet( li.ID, $childID, $b );
		}
	}
	
	// creates a virtual brightness(light) the light from a parent to a child brightness, with only light specified
	public function childGet( $ID:uint, $childID:int, $b:Lighting ):Boolean {
		
		if ( !lightHas( $ID ) )
		{
			Log.out( "Brightness.childGet - No light for ID: " + $ID, Log.WARN );
			return false;
		}	
			
		var li:LightInfo =  lightGet( $ID );

		var newLi:LightInfo = LightInfoPool.poolGet();
		newLi.setInfo( $ID, li.color, li.attn, li.avg );
		if ( !$b.add( newLi ) ) {
			//Log.out( "Brightness.childGet - $b does not have light info for lightID: " + $ID, Log.WARN )
			return false;
		}
		var sli:LightInfo =  $b.lightGet( $ID );	
				
		// I think the diagonals should be averaged between both corners
		if ( 0 == $childID ) { // b000
			sli.b000 = li.b000;
			sli.b001 = ( li.b001 + li.b000) / 2;
			sli.b010 = ( li.b010 + li.b000) / 2;				// average edge for edge points
			sli.b011 = ( li.b011 + li.b001 + li.b010 + li.b000) / 4; // average of all four on face for points on face
			sli.b100 = ( li.b100 + li.b000) / 2;
			sli.b101 = ( li.b101 + li.b000 + li.b100 + li.b001) / 4;
			sli.b110 = ( li.b110 + li.b100 + li.b000 + li.b010) / 4;
			sli.b111 = li.avg; 							// average of all eight for center points
		}
		else if ( 1 == $childID )	{ // b100
			sli.b000 = ( li.b000 + li.b100) / 2;
			sli.b001 = ( li.b101 + li.b000 + li.b100 + li.b001) / 4;
			sli.b010 = ( li.b000 + li.b100 + li.b010 + li.b110) / 4;
			sli.b011 = li.avg;
			sli.b100 = li.b100;
			sli.b101 = ( li.b101 + li.b100) / 2;
			sli.b110 = ( li.b100 + li.b110) / 2;
			sli.b111 = ( li.b100 + li.b110 + li.b101 + li.b111) / 4;
		}
		else if ( 2 == $childID )	{ // b010
			sli.b000 = ( li.b000 + li.b010) / 2;
			sli.b001 = ( li.b000 + li.b010 + li.b001 + li.b011) / 4;
			sli.b010 = li.b010;
			sli.b011 = ( li.b011 + li.b010) / 2;
			sli.b100 = ( li.b000 + li.b010 + li.b100 + li.b110) / 4;
			sli.b101 = li.avg;
			sli.b110 = ( li.b110 + li.b010) / 2;
			sli.b111 = ( li.b111 + li.b010 + li.b110 + li.b011 ) / 4;
		}
		else if ( 3 == $childID ) { // b110
			sli.b000 = ( li.b000 + li.b010 + li.b110 + li.b100 ) / 4;
			sli.b001 = li.avg;
			sli.b010 = ( li.b010 + li.b110) / 2;
			sli.b011 = ( li.b111 + li.b010 + li.b110 + li.b011 ) / 4;
			sli.b100 = ( li.b100 + li.b110) / 2;
			sli.b101 = ( li.b100 + li.b110 + li.b111 + li.b101 ) / 4;
			sli.b110 = li.b110;
			sli.b111 = ( li.b111 + li.b110) / 2;
		}
		else if ( 4 == $childID )	{ // b001
			sli.b000 = ( li.b000 + li.b001) / 2;
			sli.b001 = li.b001;
			sli.b010 = ( li.b000 + li.b010 + li.b001 + li.b011) / 4;
			sli.b011 = ( li.b011 + li.b001) / 2;
			sli.b100 = ( li.b101 + li.b000 + li.b100 + li.b001) / 4;
			sli.b101 = ( li.b101 + li.b001) / 2;
			sli.b110 = li.avg;
			sli.b111 = ( li.b001 + li.b011 + li.b101 + li.b111) / 4;
		}
		else if ( 5 == $childID )	{ // b101
			sli.b000 = ( li.b101 + li.b000 + li.b100 + li.b001) / 4;
			sli.b001 = ( li.b001 + li.b101) / 2;
			sli.b010 = li.avg;
			sli.b011 = ( li.b001 + li.b011 + li.b101 + li.b111) / 4;
			sli.b100 = ( li.b100 + li.b101) / 2;
			sli.b101 = li.b101;
			sli.b110 = ( li.b100 + li.b110 + li.b101 + li.b111) / 4;
			sli.b111 = ( li.b111 + li.b101) / 2;
		}
		else if ( 6 == $childID )	{ // b011
			sli.b000 = ( li.b000 + li.b010 + li.b011 + li.b001) / 4;
			sli.b001 = ( li.b001 + li.b011) / 2;
			sli.b010 = ( li.b010 + li.b011) / 2;
			sli.b011 = li.b011;
			sli.b100 = li.avg;
			sli.b101 = ( li.b001 + li.b011 + li.b101 + li.b111) / 4;
			sli.b110 = ( li.b010 + li.b011 + li.b110 + li.b111) / 4;
			sli.b111 = ( li.b111 + li.b011) / 2;
		}
		else if ( 7 == $childID )	{ // b111
			sli.b000 = li.avg;
			sli.b001 = ( li.b001 + li.b011 + li.b101 + li.b111 ) / 4;
			sli.b010 = ( li.b111 + li.b010 + li.b110 + li.b011 ) / 4;
			sli.b011 = ( li.b011 + li.b111) / 2;
			sli.b100 = ( li.b100 + li.b110 + li.b101 + li.b111 ) / 4;
			sli.b101 = ( li.b101 + li.b111) / 2;
			sli.b110 = ( li.b110 + li.b111) / 2;
			sli.b111 = li.b111;
		}	
		return true;
	}

	public function get avg():uint {
		var count:int;
		var avgTotal:uint;
		// I need to know the average attn, but I dont know it here....
		for ( var j:int = 0; j < _lights.length; j++ ) {
			var li:LightInfo = _lights[j];
			if ( null != li ) { // new light avg is greater then this lights avg, replace it.
				avgTotal += li.avg;
				count++;
			}
		}
		
		return avgTotal/count;
	}
	
	public function lightGet( $ID:uint ):LightInfo {
		for ( var i:int = 0; i < _lights.length; i++ )
		{
			var lightInfo:LightInfo = _lights[i];
			if ( null != lightInfo ) {
				if ( $ID == lightInfo.ID ) {
					return lightInfo;
				}
			}
		}
		return null;
	}
	
	public function lightHas( $ID:uint ):Boolean {
		for ( var i:int = 0; i < _lights.length; i++ )
		{
			var lightInfo:LightInfo = _lights[i];
			if ( null != lightInfo ) {
				if ( $ID == lightInfo.ID )
					return true;
			}
		}
		return false;
	}

	// Gets the ID of the light here
	public function lightIDGet():uint {
		for ( var i:int = 1; i < _lights.length; i++ ) {
			var li:LightInfo = _lights[i];
			if ( li && li.lightIs )
				return li.ID;
		}
		return 1;
	}

	// Gets the ID of the light here
	public function lightIDNonDefaultUsedGet():Vector.<uint> {
		var lightIDs:Vector.<uint> = new Vector.<uint>;
		for ( var i:int = 1; i < _lights.length; i++ ) {
			var li:LightInfo = _lights[i];
			if ( null != li )
				lightIDs.push( li.ID );
		}
		return lightIDs;
	}
	
	public function lightBrightestGet():LightInfo {
		var maxAttn:uint = _defaultBaseLightAttn;
		var maxAttnIndex:uint;
		// I need to know the average attn, but I dont know it here....
		for ( var j:int = 0; j < _lights.length; j++ ) {
			var li:LightInfo = _lights[j];
			if ( null != li ) { // new light avg is greater then this lights avg, replace it.
				if ( maxAttn < li.avg ) {
					maxAttn = li.avg;
					maxAttnIndex = j;
				}
			}
		}
		
		return _lights[maxAttnIndex];
	}
	
	public function addOld( $ID:uint, $color:uint, $avgAttn:uint, $attnPerMeter:uint, $lightIs:Boolean = false ):Boolean {
		
		if ( lightHas( $ID ) )
			return true;
		
		// dont add in lights who are at base attn level
		if ( DEFAULT_LIGHT_ID != $ID && _defaultBaseLightAttn == $avgAttn )
			return false;
			
		var newLi:LightInfo = LightInfoPool.poolGet();
		newLi.setInfo( $ID, $color, $attnPerMeter, Lighting.defaultBaseLightIllumination, $lightIs );

			// check for available slot first, if none found, add new light to end.
		for ( var i:int = 0; i < _lights.length; i++ ) {
			if ( null == _lights[i] ) {
				_lights[i] = newLi;	
				return true;
			}
		}
		_lights.push( newLi );
		return true;
	}

	public function add( $li:LightInfo ):Boolean {

		if ( lightHas( $li.ID ) )
			return true;

		// dont add in lights who are at base attn level
		if ( DEFAULT_LIGHT_ID != $li.ID && _defaultBaseLightAttn == $li.avg )
			return false;

		// check for available slot first, if none found, add new light to end.
		for ( var i:int = 0; i < _lights.length; i++ ) {
			if ( null == _lights[i] ) {
				_lights[i] = $li;
				return true;
			}
		}
		_lights.push( $li );
		return true;
	}

	public function remove( $ID:uint ):Boolean {
		
		if ( !lightHas( $ID ) )
			return false;
		
		for ( var i:int = 0; i < _lights.length; i++ )
		{
			var li:LightInfo = _lights[i];
			if ( null != li ) {
				if ( $ID == li.ID ) {
					LightInfoPool.poolReturn( li );
					_lights[i] = null;
					_lights.splice( i, 1 );
					return true
				}
			}
		}
		
		return false; // Should never get here
	}
	
	public function lightFullBright():void {
		var li:LightInfo = lightGet( Lighting.DEFAULT_LIGHT_ID );
		if ( li )
			li.setIlluminationLevel( Lighting.MAX_LIGHT_LEVEL );
		else
			Log.out( "Brightness.lightFullBright - MISSING DEFAULT LIGHTS", Log.WARN );
	}

	// this returns a composite color made of default color plus any additional colors for the indicated corner
	public function lightGetComposite( $face:int, $corner:uint ):uint {
		_compositeColor = 0;
		
		for ( var i:int; i < _lights.length; i++ )
		{
			var li:LightInfo = _lights[i];
			if ( null != li ) {
				_compositeColor = ColorUtils.testCombineARGB( _compositeColor, li.color, li.illuminationLevelGet( $corner ) );
			}
		}
		
		if ( Lighting.eaoEnabled ) {
			var cornerAttn:uint = cornerForFace( $face, $corner );
			if ( 0 < cornerAttn ) {
				cornerAttn = MAX_LIGHT_LEVEL - cornerAttn * li.attn * 2; // 4 for darker corners
				cornerAttn = Math.max( cornerAttn, 0 );
				_compositeColor = ColorUtils.placeAlpha( _compositeColor, cornerAttn );
	//			Log.out( "Brightness.lightGetComposite for corner - _compositeColor: " + ColorUtils.extractAlpha( _compositeColor ) );
	_compositeColor = ColorUtils.placeAlpha( _compositeColor, 0x00 );
			} else {
				_compositeColor = ColorUtils.placeAlpha( _compositeColor, MAX_LIGHT_LEVEL );
			}
		}
		return _compositeColor;
	}
		
	// returns true if this is the last face that was influenced
	public function influenceRemove( $ID:uint, $faceFrom:int ):Boolean
	{
		if ( !lightHas( $ID ) )
			return false;
		
		var of:int = Oxel.face_get_opposite( $faceFrom );	
		var li:LightInfo = lightGet( $ID );
		if ( Globals.POSX == of ) {
			
			li.b100 = _defaultBaseLightAttn;
			li.b110 = _defaultBaseLightAttn;
			li.b111 = _defaultBaseLightAttn;
			li.b101 = _defaultBaseLightAttn;
		}
		else if ( Globals.NEGX == of ) {

			li.b000 = _defaultBaseLightAttn;
			li.b010 = _defaultBaseLightAttn;
			li.b011 = _defaultBaseLightAttn;
			li.b001 = _defaultBaseLightAttn;
		}
		else if ( Globals.POSY == of ) {

			li.b010 = _defaultBaseLightAttn;
			li.b110 = _defaultBaseLightAttn;
			li.b111 = _defaultBaseLightAttn;
			li.b011 = _defaultBaseLightAttn;
		}
		else if ( Globals.NEGY == of ) {

			li.b000 = _defaultBaseLightAttn;
			li.b100 = _defaultBaseLightAttn;
			li.b101 = _defaultBaseLightAttn;
			li.b001 = _defaultBaseLightAttn;
		}
		else if ( Globals.POSZ == of ) {

			li.b001 = _defaultBaseLightAttn;
			li.b011 = _defaultBaseLightAttn;
			li.b111 = _defaultBaseLightAttn;
			li.b101 = _defaultBaseLightAttn;
		}
		else if ( Globals.NEGZ == of ) {
			
			li.b000 = _defaultBaseLightAttn;
			li.b010 = _defaultBaseLightAttn;
			li.b110 = _defaultBaseLightAttn;
			li.b100 = _defaultBaseLightAttn;
		}
		return true;
	}
	
	public function influenceAdd( $ID:uint, $lob:Lighting, $faceFrom:int, $faceOnly:Boolean, $grainUnits:int ):Boolean
	{
		// Check to make sure this FACE has values, not the whole oxel
		if ( !$lob.valuesHasForFace( $ID, $faceFrom ) ) 
			return false;

		var sli:LightInfo = $lob.lightGet( $ID );
		if ( null == sli )
			return false; // This should not really occur
		var newLi:LightInfo = LightInfoPool.poolGet();
		newLi.setInfo( $ID, sli.color, sli.avg, sli.attn );
		if ( !add( newLi ) ) {
			LightInfoPool.poolReturn(newLi);
			return false;
		}
		var li:LightInfo = lightGet( $ID );
		
		var c:Boolean = false;
		const attnScaled:uint = materialFallOffFactor * sli.attn * $grainUnits / Avatar.UNITS_PER_METER;
		
		if ( Globals.POSX == $faceFrom ) {
			
			if ( li.b000 < sli.b100 ) { li.b000 = sli.b100; c = true; }
			if ( li.b010 < sli.b110 ) { li.b010 = sli.b110; c = true; }
			if ( li.b011 < sli.b111 ) { li.b011 = sli.b111; c = true; }
			if ( li.b001 < sli.b101 ) { li.b001 = sli.b101; c = true; }
		}
		else if ( Globals.NEGX == $faceFrom ) {

			if ( li.b100 < sli.b000 ) { li.b100 = sli.b000; c = true; }
			if ( li.b110 < sli.b010 ) { li.b110 = sli.b010; c = true; }
			if ( li.b111 < sli.b011 ) { li.b111 = sli.b011; c = true; }
			if ( li.b101 < sli.b001 ) { li.b101 = sli.b001; c = true; }
		}
		else if ( Globals.POSY == $faceFrom ) {

			if ( li.b000 < sli.b010 ) { li.b000 = sli.b010; c = true; }
			if ( li.b100 < sli.b110 ) { li.b100 = sli.b110; c = true; }
			if ( li.b101 < sli.b111 ) { li.b101 = sli.b111; c = true; }
			if ( li.b001 < sli.b011 ) { li.b001 = sli.b011; c = true; }
		}
		else if ( Globals.NEGY == $faceFrom ) {

			if ( li.b010 < sli.b000 ) { li.b010 = sli.b000; c = true; }
			if ( li.b110 < sli.b100 ) { li.b110 = sli.b100; c = true; }
			if ( li.b111 < sli.b101 ) { li.b111 = sli.b101; c = true; }
			if ( li.b011 < sli.b001 ) { li.b011 = sli.b001; c = true; }
		}
		else if ( Globals.POSZ == $faceFrom ) {

			if ( li.b000 < sli.b001 ) { li.b000 = sli.b001; c = true; }
			if ( li.b010 < sli.b011 ) { li.b010 = sli.b011; c = true; }
			if ( li.b110 < sli.b111 ) { li.b110 = sli.b111; c = true; }
			if ( li.b100 < sli.b101 ) { li.b100 = sli.b101; c = true; }
		}
		else if ( Globals.NEGZ == $faceFrom ) {
			
			if ( li.b001 < sli.b000 ) { li.b001 = sli.b000; c = true; }
			if ( li.b011 < sli.b010 ) { li.b011 = sli.b010; c = true; }
			if ( li.b111 < sli.b110 ) { li.b111 = sli.b110; c = true; }
			if ( li.b101 < sli.b100 ) { li.b101 = sli.b100; c = true; }
		}
		
		//if ( !$faceOnly && max - attnScaled > avg ) {
		if ( !$faceOnly ) {
			var result:Boolean = balanceAttn( $ID, attnScaled );
			c = c || result;
		}
		
		//return c;
		return true;
	}

	public function balanceAttnAll( $attnScaling:uint ):Boolean {
		var c:Boolean = false;
		for ( var i:int = 0; i < _lights.length; i++ )
		{
			var li:LightInfo = _lights[i];
			if ( null != li ) {
				var result:Boolean = balanceAttn( li.ID, $attnScaling ) ;
				c = c || result;
			}
		}
		return c;
	}
	
	public function balanceAttn( $ID:uint, $attnScaling:uint ):Boolean {
		
		var c:Boolean = false;
		const li:LightInfo = lightGet( $ID );
		var attnScaled:uint = $attnScaling;
		const sqattn:Number = Math.sqrt( 2 * (attnScaled * attnScaled) );
		const qrattn:Number = Math.sqrt( 3 * (attnScaled * attnScaled) );
		// Do this for each adject vertice
		if ( li.b000 > li.b001 + attnScaled ) { li.b001 = li.b000 - attnScaled; c = true; }
		if ( li.b000 > li.b010 + attnScaled ) { li.b010 = li.b000 - attnScaled; c = true; }
		if ( li.b000 > li.b011 + sqattn ) 	  	{ li.b011 = li.b000 - sqattn; c = true; }
		if ( li.b000 > li.b100 + attnScaled ) { li.b100 = li.b000 - attnScaled; c = true; }
		if ( li.b000 > li.b101 + sqattn ) 	  	{ li.b101 = li.b000 - sqattn; c = true; }
		if ( li.b000 > li.b110 + sqattn ) 	  	{ li.b110 = li.b000 - sqattn; c = true; }
		if ( li.b000 > li.b111 + qrattn ) 	  	{ li.b111 = li.b000 - qrattn; c = true; }
		
		if ( li.b001 > li.b000 + attnScaled ) { li.b000 = li.b001 - attnScaled; c = true; }
		if ( li.b001 > li.b010 + sqattn ) 	  	{ li.b010 = li.b001 - sqattn; c = true; }
		if ( li.b001 > li.b011 + attnScaled ) { li.b011 = li.b001 - attnScaled; c = true; }
		if ( li.b001 > li.b100 + sqattn ) 	  	{ li.b100 = li.b001 - sqattn; c = true; }
		if ( li.b001 > li.b101 + attnScaled ) { li.b101 = li.b001 - attnScaled; c = true; }
		if ( li.b000 > li.b110 + qrattn ) 	  	{ li.b110 = li.b001 - qrattn; c = true; }
		if ( li.b001 > li.b111 + sqattn ) 	  	{ li.b111 = li.b001 - sqattn; c = true; }
		
		if ( li.b010 > li.b000 + attnScaled ) { li.b000 = li.b010 - attnScaled; c = true; }
		if ( li.b010 > li.b001 + sqattn ) 	  	{ li.b001 = li.b010 - sqattn; c = true; }
		if ( li.b010 > li.b011 + attnScaled ) { li.b011 = li.b010 - attnScaled; c = true; }
		if ( li.b010 > li.b100 + sqattn ) 	  	{ li.b100 = li.b010 - sqattn; c = true; }
		if ( li.b010 > li.b101 + qrattn ) 	  	{ li.b101 = li.b010 - qrattn; c = true; }
		if ( li.b010 > li.b110 + attnScaled ) { li.b110 = li.b010 - attnScaled; c = true; }
		if ( li.b010 > li.b111 + sqattn ) 	  	{ li.b111 = li.b010 - sqattn; c = true; }
		
		if ( li.b011 > li.b000 + sqattn ) 	  	{ li.b000 = li.b011 - sqattn; c = true; }
		if ( li.b011 > li.b001 + attnScaled ) { li.b001 = li.b011 - attnScaled; c = true; }
		if ( li.b011 > li.b010 + attnScaled ) { li.b010 = li.b011 - attnScaled; c = true; }
		if ( li.b011 > li.b100 + qrattn )      { li.b100 = li.b011 - qrattn; c = true; }
		if ( li.b011 > li.b101 + sqattn )      { li.b101 = li.b011 - sqattn; c = true; }
		if ( li.b011 > li.b110 + sqattn )      { li.b110 = li.b011 - sqattn; c = true; }
		if ( li.b011 > li.b111 + attnScaled ) { li.b111 = li.b011 - attnScaled; c = true; }

		if ( li.b100 > li.b000 + attnScaled ) { li.b000 = li.b100 - attnScaled; c = true; }
		if ( li.b100 > li.b001 + sqattn ) 	  	{ li.b001 = li.b100 - sqattn; c = true; }
		if ( li.b100 > li.b010 + sqattn ) 	  	{ li.b010 = li.b100 - sqattn; c = true; }
		if ( li.b100 > li.b011 + qrattn ) 	  	{ li.b011 = li.b100 - qrattn; c = true; }
		if ( li.b100 > li.b101 + attnScaled ) { li.b101 = li.b100 - attnScaled; c = true; }
		if ( li.b100 > li.b110 + attnScaled ) { li.b110 = li.b100 - attnScaled; c = true; }
		if ( li.b100 > li.b111 + sqattn ) 	  	{ li.b111 = li.b100 - sqattn; c = true; }
		
		if ( li.b101 > li.b000 + sqattn ) 	  	{ li.b000 = li.b101 - sqattn; c = true; }
		if ( li.b101 > li.b001 + attnScaled ) { li.b001 = li.b101 - attnScaled; c = true; }
		if ( li.b101 > li.b010 + qrattn ) 	  	{ li.b010 = li.b101 - qrattn; c = true; }
		if ( li.b101 > li.b011 + sqattn ) 	  	{ li.b011 = li.b101 - sqattn; c = true; }
		if ( li.b101 > li.b100 + attnScaled ) { li.b100 = li.b101 - attnScaled; c = true; }
		if ( li.b101 > li.b110 + sqattn ) 	  	{ li.b110 = li.b101 - sqattn; c = true; }
		if ( li.b101 > li.b111 + attnScaled ) { li.b111 = li.b101 - attnScaled; c = true; }
		
		if ( li.b110 > li.b000 + sqattn )	  	{ li.b000 = li.b110 - sqattn; c = true; }
		if ( li.b110 > li.b001 + qrattn )	  	{ li.b001 = li.b110 - qrattn; c = true; }
		if ( li.b110 > li.b010 + attnScaled ) { li.b010 = li.b110 - attnScaled; c = true; }
		if ( li.b110 > li.b011 + sqattn )	  	{ li.b011 = li.b110 - sqattn; c = true; }
		if ( li.b110 > li.b100 + attnScaled ) { li.b100 = li.b110 - attnScaled; c = true; }
		if ( li.b110 > li.b101 + sqattn )	  	{ li.b101 = li.b110 - sqattn; c = true; }
		if ( li.b110 > li.b111 + attnScaled ) { li.b111 = li.b110 - attnScaled; c = true; }

		if ( li.b111 > li.b000 + qrattn ) 	  	{ li.b000 = li.b111 - qrattn; c = true; }
		if ( li.b111 > li.b001 + sqattn ) 	  	{ li.b001 = li.b111 - sqattn; c = true; }
		if ( li.b111 > li.b010 + sqattn ) 	  	{ li.b010 = li.b111 - sqattn; c = true; }
		if ( li.b111 > li.b011 + attnScaled ) { li.b011 = li.b111 - attnScaled; c = true; }
		if ( li.b111 > li.b100 + sqattn ) 	  	{ li.b100 = li.b111 - sqattn; c = true; }
		if ( li.b111 > li.b101 + attnScaled ) { li.b101 = li.b111 - attnScaled; c = true; }
		if ( li.b111 > li.b110 + attnScaled ) { li.b110 = li.b111 - attnScaled; c = true; }

		return c;
	}
	
	// Add the influcence of a virtual cube the same size
	public function brightnessMerge( $ID:uint, $b:Lighting ):Boolean {
		
		if ( !$b.lightHas( $ID ) )
			return false; // if there is no value for the light, it is not added
		var sli:LightInfo = $b.lightGet( $ID );
		var newLi:LightInfo = LightInfoPool.poolGet();
		newLi.setInfo( sli.ID, sli.color, sli.attn, sli.avg );
		if ( !add( newLi ) ) {
			LightInfoPool.poolReturn( newLi );
			return false;
		}
		var li:LightInfo = lightGet( $ID );
		
		var c:Boolean;
		if ( li.b000 < sli.b000 )	  { li.b000 = sli.b000; c = true; }
		if ( li.b001 < sli.b001 )	  { li.b001 = sli.b001; c = true; }
		if ( li.b010 < sli.b010 )	  { li.b010 = sli.b010; c = true; }
		if ( li.b011 < sli.b011 )	  { li.b011 = sli.b011; c = true; }
		if ( li.b100 < sli.b100 )	  { li.b100 = sli.b100; c = true; }
		if ( li.b101 < sli.b101 )	  { li.b101 = sli.b101; c = true; }
		if ( li.b110 < sli.b110 )	  { li.b110 = sli.b110; c = true; }
		if ( li.b111 < sli.b111 )	  { li.b111 = sli.b111; c = true; }
		return c;
	}

	public function cornerForFace( $face:int, $corner:uint ):uint {
		if ( Globals.POSX == $face ) {
			if (       Lighting.B100 == $corner ) 
				return posX100;
			else if (  Lighting.B101 == $corner ) 
				return posX101;
			else if (  Lighting.B110 == $corner ) 
				return posX110;
			else 
				return posX111;
		}
		else if ( Globals.NEGX == $face ) {
			if (       Lighting.B000 == $corner ) 
				return negX000;
			else if (  Lighting.B001 == $corner ) 
				return negX001;
			else if (  Lighting.B010 == $corner ) 
				return negX010;
			else if (  Lighting.B011 == $corner ) 
				return negX011;
		}
		else if ( Globals.POSY == $face ) {
			if (  	   Lighting.B010 == $corner ) 
				return posY010;
			else if (  Lighting.B011 == $corner ) 
				return posY011;
			else if (  Lighting.B110 == $corner ) 
				return posY110;
			else 
				return posY111;
		}
		else if ( Globals.NEGY == $face ) {
			if (       Lighting.B000 == $corner ) 
				return negY000;
			else if (  Lighting.B001 == $corner ) 
				return negY001;
			else if (  Lighting.B100 == $corner ) 
				return negY100;
			else if (  Lighting.B101 == $corner ) 
				return negY101;
		}
		else if ( Globals.POSZ == $face ) {
			if (  Lighting.B001 == $corner ) 
				return posZ001;
			else if (  Lighting.B101 == $corner ) 
				return posZ101;
			else if (  Lighting.B011 == $corner ) 
				return posZ011;
			else 
				return posZ111;
		}
		else if ( Globals.NEGZ == $face ) {
			
			if (       Lighting.B000 == $corner ) 
				return negZ000;
			else if (  Lighting.B100 == $corner ) 
				return negZ100;
			else if (  Lighting.B010 == $corner ) 
				return negZ010;
			else 
				return negZ110;
		}
		return 0;
	}
	
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
	private function setEdgeAdjacent( $oxel:Oxel, $majorFace:int, $edgeFace:int, $adjustVal:uint ):void {
		var an:Oxel;
 		if ( Globals.POSX == $majorFace ) {
			
			if ( Globals.POSY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posX110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}
		else if ( Globals.NEGX == $majorFace ) {
			if ( Globals.POSY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			} 
			else if ( Globals.NEGY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negX010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}
		else if ( Globals.POSY == $majorFace ) 
		{
			if ( Globals.POSX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posY110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}
		else if ( Globals.NEGY == $majorFace ) {

			if ( Globals.POSX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGZ);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negY100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}
		else if ( Globals.POSZ == $majorFace ) {

			if ( Globals.POSX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ011 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ111 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ001 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.posZ101 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}
		else if ( Globals.NEGZ == $majorFace ) {
			
			if ( Globals.POSX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGX == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGY);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.POSY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ010 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ110 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
			else if ( Globals.NEGY == $edgeFace ) {
				an = $oxel.neighbor(Globals.POSX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ000 = $adjustVal;
					an.quadRebuild( $majorFace ); }
					
				an = $oxel.neighbor(Globals.NEGX);
				if ( Oxel.validLightable( an ) ) {
					an.lighting.negZ100 = $adjustVal;
					an.quadRebuild( $majorFace ); }
			}
		}

	}
	
	private function edgeValueSet( $majorFace:int, $edgeFace:int, $changeValue:uint ):void {
		
		if ( Globals.POSX == $majorFace ) {
			
			if ( Globals.POSY == $edgeFace ) {
				posX110 = $changeValue;
				posX111 = $changeValue;
				posY = $changeValue;
			}
			else if ( Globals.NEGY == $edgeFace ) {
				posX100 = $changeValue;
				posX101 = $changeValue;
				negY = $changeValue;
			}
			else if ( Globals.POSZ == $edgeFace ) {
				posX101 = $changeValue;
				posX111 = $changeValue;
				posZ = $changeValue;
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				posX110 = $changeValue;
				posX100 = $changeValue;
				negZ = $changeValue;
			}
		}
		else if ( Globals.NEGX == $majorFace ) {
			if ( Globals.POSY == $edgeFace ) {
				negX010 = $changeValue;
				negX011 = $changeValue;
				posY = $changeValue;
			}
			else if ( Globals.NEGY == $edgeFace ) {
				negX000 = $changeValue;
				negX001 = $changeValue;
				negY = $changeValue;
			}
			else if ( Globals.POSZ == $edgeFace ) {
				negX001 = $changeValue;
				negX011 = $changeValue;
				posZ = $changeValue;
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				negX000 = $changeValue;
				negX010 = $changeValue;
				negZ = $changeValue;
			}
		}
		else if ( Globals.POSY == $majorFace ) {
			if ( Globals.POSX == $edgeFace ) {
				posY110 = $changeValue;
				posY111 = $changeValue;
				posX = $changeValue;
			}
			else if ( Globals.NEGX == $edgeFace ) {
				posY010 = $changeValue;
				posY011 = $changeValue;
				negX = $changeValue;
			}
			else if ( Globals.POSZ == $edgeFace ) {
				posY011 = $changeValue;
				posY111 = $changeValue;
				posZ = $changeValue;
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				posY010 = $changeValue;
				posY110 = $changeValue;
				negZ = $changeValue;
			}
		}
		else if ( Globals.NEGY == $majorFace ) {

			if ( Globals.POSX == $edgeFace ) {
				negY100 = $changeValue;
				negY101 = $changeValue;
				posX = $changeValue;
			}
			else if ( Globals.NEGX == $edgeFace ) {
				negY000 = $changeValue;
				negY001 = $changeValue;
				negX = $changeValue;
			}
			else if ( Globals.POSZ == $edgeFace ) {
				negY001 = $changeValue;
				negY101 = $changeValue;
				posZ = $changeValue;
			}
			else if ( Globals.NEGZ == $edgeFace ) {
				negY000 = $changeValue;
				negY100 = $changeValue;
				negZ = $changeValue;
			}
		}
		else if ( Globals.POSZ == $majorFace ) {

			if ( Globals.POSX == $edgeFace ) {
				posZ101 = $changeValue;
				posZ111 = $changeValue;
				posX = $changeValue;
			}
			else if ( Globals.NEGX == $edgeFace ) {
				posZ001 = $changeValue;
				posZ011 = $changeValue;
				negX = $changeValue;
			}
			else if ( Globals.POSY == $edgeFace ) {
				posZ011 = $changeValue;
				posZ111 = $changeValue;
				posY = $changeValue;
			}
			else if ( Globals.NEGY == $edgeFace ) {
				posZ001 = $changeValue;
				posZ101 = $changeValue;
				negY = $changeValue;
			}
		}
		else if ( Globals.NEGZ == $majorFace ) {
			
			if ( Globals.POSX == $edgeFace ) {
				negZ100 = $changeValue;
				negZ110 = $changeValue;
				posX = $changeValue;
			}
			else if ( Globals.NEGX == $edgeFace ) {
				negZ000 = $changeValue;
				negZ010 = $changeValue;
				negX = $changeValue;
			}
			else if ( Globals.POSY == $edgeFace ) {
				negZ010 = $changeValue;
				negZ110 = $changeValue;
				posY = $changeValue;
			}
			else if ( Globals.NEGY == $edgeFace ) {
				negZ000 = $changeValue;
				negZ100 = $changeValue;
				negY = $changeValue;
			}
		}
	}
	
	private function incrementCorner( $majorFace:int, $minorFace:int, $corner:int ):void {
		
 		if ( Globals.POSX == $majorFace ) {
			
			if ( Globals.POSY == $minorFace ) {
				if ( 0 == $corner )
					posX110 = CORNER_BUMP_VAL;
				else
					posX111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGY == $minorFace ) {
				posX100 = CORNER_BUMP_VAL;
				posX101 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSZ == $minorFace ) {
				posX101 = CORNER_BUMP_VAL;
				posX111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGZ == $minorFace ) {
				posX110 = CORNER_BUMP_VAL;
				posX100 = CORNER_BUMP_VAL;
			}
		}
		else if ( Globals.NEGX == $majorFace ) {
			if ( Globals.POSY == $minorFace ) {
				negX010 = CORNER_BUMP_VAL;
				negX011 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGY == $minorFace ) {
				negX000 = CORNER_BUMP_VAL;
				negX001 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSZ == $minorFace ) {
				negX001 = CORNER_BUMP_VAL;
				negX011 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGZ == $minorFace ) {
				negX000 = CORNER_BUMP_VAL;
				negX010 = CORNER_BUMP_VAL;
			}
		}
		else if ( Globals.POSY == $majorFace ) 
		{
			if ( Globals.POSX == $minorFace ) {
				posY110 = CORNER_BUMP_VAL;
				posY111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGX == $minorFace ) {
				posY010 = CORNER_BUMP_VAL;
				posY011 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSZ == $minorFace ) {
				posY011 = CORNER_BUMP_VAL;
				posY111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGZ == $minorFace ) {
				posY010 = CORNER_BUMP_VAL;
				posY110 = CORNER_BUMP_VAL;
			}
		}
		else if ( Globals.NEGY == $majorFace ) {

			if ( Globals.POSX == $minorFace ) {
				negY100 = CORNER_BUMP_VAL;
				negY101 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGX == $minorFace ) {
				negY000 = CORNER_BUMP_VAL;
				negY001 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSZ == $minorFace ) {
				negY001 = CORNER_BUMP_VAL;
				negY101 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGZ == $minorFace ) {
				negY000 = CORNER_BUMP_VAL;
				negY100 = CORNER_BUMP_VAL;
			}
		}
		else if ( Globals.POSZ == $majorFace ) {

			if ( Globals.POSX == $minorFace ) {
				posZ101 = CORNER_BUMP_VAL;
				posZ111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGX == $minorFace ) {
				posZ001 = CORNER_BUMP_VAL;
				posZ011 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSY == $minorFace ) {
				posZ011 = CORNER_BUMP_VAL;
				posZ111 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGY == $minorFace ) {
				posZ001 = CORNER_BUMP_VAL;
				posZ101 = CORNER_BUMP_VAL;
			}
		}
		else if ( Globals.NEGZ == $majorFace ) {
			
			if ( Globals.POSX == $minorFace ) {
				negZ100 = CORNER_BUMP_VAL;
				negZ110 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGX == $minorFace ) {
				negZ000 = CORNER_BUMP_VAL;
				negZ010 = CORNER_BUMP_VAL;
			}
			else if ( Globals.POSY == $minorFace ) {
				negZ010 = CORNER_BUMP_VAL;
				negZ110 = CORNER_BUMP_VAL;
			}
			else if ( Globals.NEGY == $minorFace ) {
				negZ000 = CORNER_BUMP_VAL;
				negZ100 = CORNER_BUMP_VAL;
			}
		}
	}
	
	
	public function occlusionResetAll():void {
		_lowerAmbient = 0;
		_higherAmbient = 0;
	}
	
	public function occlusionResetFace( $face:int ):void {
 		if ( Globals.POSX == $face ) {
			posX110 = CORNER_RESET_VAL;
			posX111 = CORNER_RESET_VAL;
			posX100 = CORNER_RESET_VAL;
			posX101 = CORNER_RESET_VAL;
		}
		else if ( Globals.NEGX == $face ) {
			negX010 = CORNER_RESET_VAL;
			negX011 = CORNER_RESET_VAL;
			negX000 = CORNER_RESET_VAL;
			negX001 = CORNER_RESET_VAL;
		}
		else if ( Globals.POSY == $face ) 	{
			posY110 = CORNER_RESET_VAL;
			posY111 = CORNER_RESET_VAL;
			posY010 = CORNER_RESET_VAL;
			posY011 = CORNER_RESET_VAL;
		}
		else if ( Globals.NEGY == $face ) {
			negY100 = CORNER_RESET_VAL;
			negY101 = CORNER_RESET_VAL;
			negY000 = CORNER_RESET_VAL;
			negY001 = CORNER_RESET_VAL;
		}
		else if ( Globals.POSZ == $face ) {
			posZ101 = CORNER_RESET_VAL;
			posZ111 = CORNER_RESET_VAL;
			posZ001 = CORNER_RESET_VAL;
			posZ011 = CORNER_RESET_VAL;
		}
		else if ( Globals.NEGZ == $face ) {
			negZ100 = CORNER_RESET_VAL;
			negZ110 = CORNER_RESET_VAL;
			negZ000 = CORNER_RESET_VAL;
			negZ010 = CORNER_RESET_VAL;
		}
	}
	
	public function evaluateAmbientOcculusionNew( $o:Oxel, $face:int ):void {
		
		// get the oxel next to the face we are evaluating.
		var no:Oxel = $o.neighbor( $face );
		if ( OxelBad.INVALID_OXEL == no )
			return;
		// if the neighbor is solid, return
		if ( false == TypeInfo.hasAlpha( no.type ) )
			return;
			
		if ( $o.gc.grain < no.gc.grain )
			eaoLarger( no, $face );
		else
			eaoEqual( no, $face );
			
	}
	
	public function  eaoEqual( $no:Oxel, $face:int ):void {
		//		var childId:uint = $o.gc.childId();
		// get a list of the faces this face is adjucent to.
		var afs:Array = Globals.adjacentFaces( $face );
/*		
		var nno:Oxel;
		// now for each face that is perpendicular to the neighbor oxel
		for ( var index:int = 0; index < 5; index++ ) {
			var af:int = afs[index];
			nno = $no.neighbor( af );
			if ( !Oxel.validLightable( nno ) )
				continue;
			// no perpendicular face to cast shadow
			if ( TypeInfo.AIR == nno.type && !nno.childrenHas() )
				continue;
				
			if ( nno.gc.grain > $o.gc.grain )  // implies it has no children.
				projectOnLargerGrain( $o, nno, $face, af );
			else if ( no.gc.grain == $o.gc.grain ) // equal grain can have children
				projectOnEqualGrain( $o, nno, $face, af );
			else
				Log.out( "LightAdd.evaluateAmbientOcculusion - invalid condition - neighbor is smaller: ", Log.ERROR );
		}
*/		
	}

	public function  eaoLarger( $no:Oxel, $face:int ):void {
		
	}

	// $addOrRemoveAmbient should be either Lighting.AMBIENT_ADD or Lighting.AMBIENT_REMOVE
	public function evaluateAmbientOcculusion( $o:Oxel, $face:int, $addOrRemoveAmbient:Boolean ):void {
		
		if ( !eaoEnabled )
			return;
		
		// get the oxel next to the face we are evaluating.
		var no:Oxel = $o.neighbor( $face );
		if ( OxelBad.INVALID_OXEL == no )
			return;
		// if the neighbor is solid, return
		if ( false == TypeInfo.hasAlpha( no.type ) )
			return;
			
		//		var childId:uint = $o.gc.childId();
		// get a list of the faces this face is adjucent to.
		var afs:Array = Globals.adjacentFaces( $face );
		
		var nno:Oxel;
		var addOrRemove:Boolean;
		// now for each face that is perpendicular to the neighbor oxel
		for ( var index:int = 0; index < 5; index++ ) {
			var af:int = afs[index];
			nno = no.neighbor( af );
			if ( !Oxel.validLightable( nno ) )
				continue;
			// no perpendicular face to cast shadow
			else if ( TypeInfo.AIR == nno.type && !nno.childrenHas() )
				continue;
				
			extracted(nno, $o, $face, af, $addOrRemoveAmbient, no, index);
		}
	}

	private function extracted(nno:Oxel, $o:Oxel, $face:int, af:int, $addOrRemoveAmbient:Boolean, no:Oxel, $index:int ):void {
		if (nno.gc.grain > $o.gc.grain)  // implies it has no children.
			projectOnLargerGrain($o, nno, $face, af, $addOrRemoveAmbient, $index);
		else if (no.gc.grain == $o.gc.grain) // equal grain can have children
			projectOnEqualGrain($o, nno, $face, af, $addOrRemoveAmbient);
		else
			Log.out("Lighting.extracted - invalid condition - neighbor is smaller: ", Log.ERROR);
	}
	
	public function projectOnLargerGrain( $o:Oxel, $nno:Oxel, $face:int, $af:int, $addOrRemoveAmbient:Boolean, $index:int ):void {
		
		// So I am evaluating a larger grain next to me.
		// depending on my child location I may or may not have a face that effects me.

		// if the nno is great then one size larger, do nothing.
		if ( $o.gc.grain + 1 < $nno.gc.grain )
			return;
		
		// the nno is 1 grain larger.
		// So now I need to identify which child I am next to. Hm...
		if ( $nno.childrenHas() ) {
            // if it has child then I should have gotten the child!
		}
		else {
			// The adjuenct face is larger
            $nno.childrenCreate( false );

			var no:Oxel = $o.neighbor( $af );
			extracted($nno, $o, $face, $af, $addOrRemoveAmbient, no, $index);


			// So if $o is located on the edge, we influence one corner only
			// if $o is in the center, there is nothing to do
		}
		
	}
	
	public function projectOnEqualGrain( $o:Oxel, $nno:Oxel, $face:int, $af:int, $addOrRemoveAmbient:Boolean ):void {

		if ( $nno.childrenHas() ) {
			// Same grain size, but made up of smaller grainer.
			// So grab the child kittycorner to $o
			var oxelPair:Object = $nno.childrenForKittyCorner( $face, $af );
			//if ( TypeInfo.AIR != oxelPair.a.type ) {
				//
			//}
			//if ( TypeInfo.AIR != oxelPair.b.type ) {
				//
			//}
		}
		else if ( $nno.faceHas( Oxel.face_get_opposite( $af ) ) ) {
			
			if ( AMBIENT_ADD == $addOrRemoveAmbient ) {
				// bump the count on edge of tested oxel.
				$o.lighting.edgeValueSet( $face, $af, CORNER_BUMP_VAL );
				// bump the count on edge of tested oxel.
				// TODO - Could this bump it too far?
				$nno.lighting.edgeValueSet( Oxel.face_get_opposite( $af ), Oxel.face_get_opposite( $face ), CORNER_BUMP_VAL );
				// Problem with this is it makes the next frame dirty too, which causes every frame to be dirty, not good!
				//nno.quadMarkDirty( Oxel.face_get_opposite( af ) );
				$nno.quadRebuild( Oxel.face_get_opposite( $af ) );
				
				$nno.lighting.setEdgeAdjacent( $nno, Oxel.face_get_opposite( $af ), Oxel.face_get_opposite( $face ), CORNER_BUMP_VAL );
			}
			else { 
				// bump the count on edge of tested oxel.
				$o.lighting.edgeValueSet( $face, $af, CORNER_RESET_VAL );
				// bump the count on edge of tested oxel.
				// TODO - Could this bump it too far?
				$nno.lighting.edgeValueSet( Oxel.face_get_opposite( $af ), Oxel.face_get_opposite( $face ), CORNER_RESET_VAL );
				// Problem with this is it makes the next frame dirty too, which causes every frame to be dirty, not good!
				//nno.quadMarkDirty( Oxel.face_get_opposite( af ) );
				$nno.quadRebuild( Oxel.face_get_opposite( $af ) );
				
				$nno.lighting.setEdgeAdjacent( $nno, Oxel.face_get_opposite( $af ), Oxel.face_get_opposite( $face ), CORNER_RESET_VAL );
			}
		}
	}
	
	public function rotateQuad( $face:int ):Boolean {
		// We dont want single points of light to be on a diagonal;
		switch ( $face ) 
		{
			case Globals.POSX:
				if ( ( 1 == posX111 || 1 == posX100 ) && 0 == posX110 && 0 == posX101 )
					return true;
				if ( ( 2 == posX111 || 2 == posX100 ) && 1 == posX110 && 1 == posX101 )
					return true;
				break;
				
			case Globals.NEGX:
				if ( ( 1 == negX011 || 1 == negX000 ) && 0 == negX010 && 0 == negX001 )
					return true;
				if ( ( 2 == negX011 || 2 == negX000 ) && 1 == negX010 && 1 == negX001 )
					return true;
				break;
				
			case Globals.NEGY:
				if ( ( 1 == negY000 || 1 == negY101 ) && 0 == negY100 && 0 == negY001 )
					return true;
				if ( ( 2 == negY000 || 2 == negY101 ) && 1 == negY100 && 1 == negY001 )
					return true;
				break;
				
			case Globals.POSY:
				if ( ( 1 == posY010 || 1 == posY111 ) && 0 == posY110 && 0 == posY011 )
					return true;
				if ( ( 2 == posY010 || 2 == posY111 ) && 1 == posY110 && 1 == posY011 )
					return true;
				break;

			case Globals.POSZ:
				if ( ( 1 == posZ001 || 1 == posZ111 ) && 0 == posZ011 && 0 == posZ101 )
					return true;
				if ( ( 2 == posZ001 || 2 == posZ111 ) && 1 == posZ011 && 1 == posZ101 )
					return true;
				break;
				
			case Globals.NEGZ:
				if ( ( 1 == negZ000 || 1 == negZ110 ) && 0 == negZ100 && 0 == negZ010 )
					return true;
				if ( ( 2 == negZ000 || 2 == negZ110 ) && 1 == negZ100 && 1 == negZ010 )
					return true;
				break;
				
			default:
				Log.out( "Lighting.rotateQuad - face INVALID", Log.ERROR );
			}
		
		
		return false;
	}
	
} // end of class Brightness
} // end of package
