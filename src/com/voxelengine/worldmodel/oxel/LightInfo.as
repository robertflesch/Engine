/*==============================================================================
  Copyright 2011-2013 Robert Flesch
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

	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.utils.ColorUtils;
	
/**
 * ...
 * @author Robert Flesch
 * This holds all of the color and attenuation for one color in an oxel
 */

public class LightInfo
{
	public static const MAX:uint = 0xff;

	private var _lightIs:Boolean;		// Is this object indeed a light source, or just an air oxel
	public function get lightIs():Boolean { return _lightIs; }

	public var processed:Boolean;	// has this color has been used to project on its neighbors
	public var ID:uint;				// The ID of the light
	public var color:uint;			// the RGBA color info
	private var bLower:uint; 		// The 0xff values for the lower corners are stored in this uint
	private var bHigher:uint; 		// The 0xff values for the upper corners are stored in this uint
	public var attn:uint;
	
	
	public function LightInfo() {
	}

	public function setInfo( $ID:uint
			               , $color:uint
			               , $baseAttn:uint
			               , $baseLightIllumination:uint
			               , $lightIs:Boolean = false ):void {
//		if ( Lighting.DEFAULT_LIGHT_ID == $ID )
//				Log.out( "LightInfo.default");
		ID = $ID;
		color = $color;
		_lightIs = $lightIs;
		attn = $baseAttn;
		if ( true == $lightIs )
			setAll( 255 );
		else
			setAll( $baseLightIllumination );
	}

	public function toByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeBoolean( _lightIs );
		$ba.writeUnsignedInt( ID );
		$ba.writeUnsignedInt( color );
		$ba.writeUnsignedInt( bLower );
		$ba.writeUnsignedInt( bHigher );
//		Log.out( "LightInfo.toByteArray lightIs: \t\t" + _lightIs);
//		Log.out( "LightInfo.toByteArray ID: \t\t\t" + ID);
//		Log.out( "LightInfo.toByteArray color: \t\t" + color.toString(16));
//		Log.out( "LightInfo.toByteArray bLower: \t\t" + bLower.toString(16));
//		Log.out( "LightInfo.toByteArray bHigher: \t\t" + bHigher.toString(16));
		return $ba;
	}

	public function fromByteArray( $ba:ByteArray ):ByteArray {
		try {
			_lightIs 	= $ba.readBoolean();
			ID 			= $ba.readUnsignedInt();
			color 		= $ba.readUnsignedInt();
			bLower		= $ba.readUnsignedInt();
			bHigher 	= $ba.readUnsignedInt();
//			Log.out("LightInfo.fromByteArray \t\t\tlightIs: \t" + _lightIs);
//			Log.out("LightInfo.fromByteArray \t\t\tID: \t\t" + ID);
//			Log.out("LightInfo.fromByteArray \t\t\tcolor: \t" + color.toString(16));
//			Log.out("LightInfo.fromByteArray \t\t\tbLower: \t" + bLower.toString(16));
//			Log.out("LightInfo.fromByteArray \t\t\tbHigher: \t" + bHigher.toString(16));
		}
		catch( e:Error ){
			Log.out( "LightinInfo.fromByteArray error: " + e.toString() );
		}
		return $ba;
	}

	public function fromObject( $obj:Object ):void {
		_lightIs 	= $obj._lightIs;
		ID 			= $obj.ID;
		color 		= $obj.color;
		bLower		= $obj.bLower;
		bHigher 	= $obj.bHigher;
	}

	static public function fromByteArrayEvaluator( $ba:ByteArray, $obj:Object ):ByteArray {
		$obj.lightIs 	= $ba.readBoolean();
		$obj.ID 		= $ba.readUnsignedInt();
		$obj.color 		= $ba.readUnsignedInt();
		$obj.bLower		= $ba.readUnsignedInt();
		$obj.bHigher 	= $ba.readUnsignedInt();
		return $ba;
	}


	private function toHex( val:uint ):String {
		var str:String = "";
		str = val.toString(16)
		return ( ("0x00000000").substr(2,8 - str.length) + str );
	}
	
	private function addLeadingZero( $val:String ):String {
		var leadingZeroes:String = "000";
		leadingZeroes = leadingZeroes.substr(0, leadingZeroes.length - $val.length);
		return leadingZeroes + $val;
	}
	
	private function toLightLevel( val:uint ):String {
		var str:String = "";
		var tmp:uint = val;
		tmp = (tmp >>> 24) & 0xff;
		str += addLeadingZero( tmp.toString(10)) ;
		str += "-";
		tmp = val;
		tmp = (tmp >> 16) & 0xff;
		str += addLeadingZero(tmp.toString(10));
		str += "-";
		tmp = val;
		tmp = (tmp >> 8) & 0xff;
		str += addLeadingZero(tmp.toString(10));
		str += "-";
		tmp = val;
		tmp = (tmp >> 0) & 0xff;
		str += addLeadingZero(tmp.toString(10));
		return str;
	}
	
	public function toString():String {
		return toStringDetail();
	}
	public function toStringShort():String {
		return (" LightInfo - ID: " + ID + "\tcolor: " + toHex(color) + " bLower: " + toHex(bLower) + " bHigher: " + toHex(bHigher) + " lightIs: " + _lightIs + "\n" );
	}

	public function toStringDetail():String {
		return (" LightInfo - ID: " + ID + "\tcolor: " + toHex(color) + " bLower: " + toLightLevel(bLower) + " bHigher: " + toLightLevel(bHigher) + " lightIs: " + _lightIs + "\n" );
	}
	
	public function copyFrom( $li:LightInfo ):void {
		ID = $li.ID;
		color = $li.color;
		bLower = $li.bLower;
		bHigher = $li.bHigher;
		_lightIs = $li._lightIs;
		attn = $li.attn;
	}
	
	public function get avg():uint {
		return (b000 + b010 + b011 + b001 + b100 + b110 +  b111 + b101)/8
	}
	
	public function valuesHas( $minLevel:uint ):Boolean {
		if ( $minLevel == avg )
			return false;
		return true;
	}

	public function setAll( $attn:uint ):void	{
		
		if ( LightInfo.MAX < $attn ) {
			$attn = LightInfo.MAX
			Log.out( "LightInfo.setAll - attn > MAX" );
		}

		b000 = $attn;
		b001 = $attn;
		b100 = $attn;
		b101 = $attn;
		b010 = $attn;
		b011 = $attn;
		b110 = $attn;
		b111 = $attn;
	}
	
	public function attnLevelGet( $corner:uint ):uint {
		if (       Lighting.B000 == $corner ) 
			return b000;
		else if (  Lighting.B001 == $corner ) 
			return b001;
		else if (  Lighting.B100 == $corner ) 
			return b100;
		else if (  Lighting.B101 == $corner ) 
			return b101;
		else if (  Lighting.B010 == $corner ) 
			return b010;
		else if (  Lighting.B011 == $corner ) 
			return b011;
		else if (  Lighting.B110 == $corner ) 
			return b110;
		else 
			return b111; // if (  Brightness.B111 ) 
		
		return 0xff;
	}
	
	public function get b000():uint { return ((bLower  & 0x000000ff)); }
	public function get b001():uint { return ((bLower  & 0x0000ff00) >> 8); }
	public function get b100():uint { return ((bLower  & 0x00ff0000) >> 16); }
	public function get b101():uint { return ((bLower  & 0xff000000) >>> 24); }
	public function get b010():uint { return ((bHigher & 0x000000ff)); }
	public function get b011():uint { return ((bHigher & 0x0000ff00) >> 8); }
	public function get b110():uint { return ((bHigher & 0x00ff0000) >> 16); }
	public function get b111():uint { return ((bHigher & 0xff000000) >>> 24); }
	
	public function set b000( attn:uint ):void { bLower  = ((bLower  & 0xffffff00) | attn); }
	public function set b001( attn:uint ):void { bLower  = ((bLower  & 0xffff00ff) | (attn << 8)); }
	public function set b100( attn:uint ):void { bLower  = ((bLower  & 0xff00ffff) | (attn << 16)); }
	public function set b101( attn:uint ):void { bLower  = ((bLower  & 0x00ffffff) | (attn << 24)); }
	public function set b010( attn:uint ):void { bHigher = ((bHigher & 0xffffff00) | attn); }
	public function set b011( attn:uint ):void { bHigher = ((bHigher & 0xffff00ff) | (attn << 8)); }
	public function set b110( attn:uint ):void { bHigher = ((bHigher & 0xff00ffff) | (attn << 16)); }
	public function set b111( attn:uint ):void { bHigher = ((bHigher & 0x00ffffff) | (attn << 24)); }
	
} // end of class LightInfo
} // end of package
