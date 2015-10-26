/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
	import adobe.utils.ProductManager;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.TypeInfo;
/**
 * ...
 * @author Robert Flesch 
 */
public class FlowScaling
{
	private const CORNER_MIN:Number = 1;
	private const DEFAULT_SCALE:Number = 16;
	private const DEFAULT_TOTAL_SCALE:uint = 0xffffffff;
	
	// has scaling for this oxel be calcualted
	private var _calculated:Boolean = false
	private var _scaleRate:Number = 2;
	public function get calculated():Boolean { return _calculated; }
	
	private var _scale:uint = DEFAULT_TOTAL_SCALE;
	public function get PxPz():uint { return ((_scale  & 0x0000000f)) + 1; }
	public function get PxNz():uint { return ((_scale  & 0x000000f0) >> 4 ) + 1; }
	public function get NxNz():uint { return ((_scale  & 0x00000f00) >> 8 ) + 1; }
	public function get NxPz():uint { return ((_scale  & 0x0000f000) >> 12 ) + 1; }
	
	public function set PxPz( value:uint ):void { _scale = ((_scale & 0xfffffff0) | ( value - 1 )); }
	public function set PxNz( value:uint ):void { _scale = ((_scale & 0xffffff0f) | (( value - 1 ) << 4) ); }
	public function set NxNz( value:uint ):void { _scale = ((_scale & 0xfffff0ff) | (( value - 1 ) << 8) ); }
	public function set NxPz( value:uint ):void { _scale = ((_scale & 0xffff0fff) | (( value - 1 ) << 12) ); }
	
	/*
	 *               _____Nz_____
	 *              |            | 
	 *              |            | 
	 *              |            |
	 *              |NxPz    PxPz|
	 *  ____________|____________|____________
	 * |            |            |            |
	 * |        PxNz|NxNz    PxNz|NxNz        |
	 * Nx            |            |           Px
	 * |        PxPz|NxPz    PxPz|NxPz        |
	 * |____________|____________|____________|
	 *              |            |
	 *              |NxNz    PxNz|
	 *              |            |
	 *              |            |
	 *              |_____Pz_____|
	 * 
	 */
	public function FlowScaling():void {}
	public function has():Boolean { return ( _scale != DEFAULT_TOTAL_SCALE ) }
	
	public function toByteArray( $ba:ByteArray ):ByteArray {
		
		$ba.writeUnsignedInt( _scale );
		return $ba;
	}
	
	public function fromByteArray( $version:int, $ba:ByteArray ):ByteArray {
		// No need to handle versions yet
		if ( Globals.VERSION_004 == $version || Globals.VERSION_003 == $version ) {
			PxPz = rnd( $ba.readFloat() );
			PxNz = rnd( $ba.readFloat() );
			NxNz = rnd( $ba.readFloat() );
			NxPz = rnd( $ba.readFloat() );
		}
		else {
			_scale = $ba.readUnsignedInt();
		}
		return $ba;
		
		function rnd( $val:Number ):Number {
			return int($val*100)/100;
		}
	}
	 
	/*
	 * This function resets the scale of an oxel, for example if another oxel of same type flows over it.
	 * There are two phases, reseting of this oxels scale, and the resetting of the oxels around it.
	 */
	public function reset( $oxel:Oxel = null ):void	{
		//Log.out( "FlowScaling.scalingReset oxel: " + toString() );
		// This is telling us we dont need no stinking scaling, however our neighbors might
		_calculated = false;
		// first reset this oxels scaling
		if ( has() ) {
			_scale = DEFAULT_TOTAL_SCALE
			if ( $oxel )
				$oxel.rebuildAll();
		}
	}
	
	public function setToDefault( $oxel:Oxel = null ):void	{
		Log.out( "FlowScaling.setToDefault oxel: " + toString() );
		// This is telling us we dont need no stinking scaling, however our neighbors might
		reset()
		_calculated = true;
	}
	
	public function neighborsRecalc( $oxel:Oxel ):void	{
		// now check to see if we need to reset the scaling of our neighbors
		for each ( var dir:int in Globals.horizontalDirections )
		{
			var fromOxel:Oxel = $oxel.neighbor( dir );
			if ( Globals.BAD_OXEL == fromOxel )
				continue;
				
			if ( fromOxel.type == $oxel.type && null != fromOxel.flowInfo )
				fromOxel.flowInfo.flowScaling.recalculate( fromOxel );
		}
	}
	
	
	public function recalculate( $oxel:Oxel ):void	{
		if ( !has() )
			return;
			
		Log.out( "FlowScaling.scaleRecalculate was: " + toString() );
		_calculated = false;
		calculate( $oxel );
		$oxel.rebuildAll();
		Log.out( "FlowScaling.scaleRecalculate is: " + toString() );
	}
	
	public function calculate( $oxel:Oxel ):void	{
		if ( _calculated )
			return;
	
		Log.out( "FlowScaling.scaleCalculate was: " + toString() );
		_calculated = true;
		// set these to a minimum level, so that their influence for the other corners can be felt
		_scale = 0x00000000;
		
		for each ( var horizontalDir:int in Globals.horizontalDirections )
		{
			grabNeighborInfluences( $oxel, horizontalDir );
		}
		
		// if these corners have not been influenced by another vert
		// set them to scale
		var fi:FlowInfo = $oxel.flowInfo; // Scale uses my out
		if ( CORNER_MIN == PxPz )
			PxPz = fi.scale()/_scaleRate;
		if ( CORNER_MIN == PxNz )
			PxNz = fi.scale()/_scaleRate;
		if ( CORNER_MIN == NxNz )
			NxNz = fi.scale()/_scaleRate;
		if ( CORNER_MIN == NxPz )
			NxPz = fi.scale()/_scaleRate;
		Log.out( "FlowScaling.scalingCalculate is: " + toString() );
	}
		
	private function grabNeighborInfluences( $oxel:Oxel, $dir:int ):void {
		
		var fromOxel:Oxel = $oxel.neighbor( Oxel.face_get_opposite( $dir ) );
		if ( Globals.BAD_OXEL == fromOxel )
			return;
			
		//if ( fromOxel.type == $oxel.type )
		if ( TypeInfo.typeInfo[fromOxel.type].flowable && fromOxel.flowInfo && fromOxel.flowInfo.flowScaling && $oxel.flowInfo.flowScaling )
		{
			var fromRecalc:Boolean = false;
			var fromOxelScale:FlowScaling = fromOxel.flowInfo.flowScaling;
			if ( Globals.POSX == $dir )
			{
				NxPz = Math.max( NxPz, fromOxelScale.PxPz );
				if ( fromOxelScale.PxPz < NxPz )
					fromRecalc = true;
				NxNz = Math.max( NxNz, fromOxelScale.PxNz );
				if ( fromOxelScale.PxNz < NxNz )
					fromRecalc = true;
			}
			else if ( Globals.NEGX == $dir )
			{
				PxNz = Math.max( PxNz, fromOxelScale.NxNz );
				if ( fromOxelScale.NxNz < PxNz )
					fromRecalc = true;
				PxPz = Math.max( PxPz, fromOxelScale.NxPz );
				if ( fromOxelScale.PxPz < NxPz )
					fromRecalc = true;
			}   
			else if ( Globals.POSZ == $dir )
			{
				NxNz = Math.max( NxNz, fromOxelScale.NxPz );
				if ( fromOxelScale.NxPz < NxNz )
					fromRecalc = true;
				PxNz = Math.max( PxNz, fromOxelScale.PxPz );
				if ( fromOxelScale.PxNz < PxNz )
					fromRecalc = true;
			}   
			else if ( Globals.NEGZ == $dir )
			{
				NxPz = Math.max( NxPz, fromOxelScale.NxNz );
				if ( fromOxelScale.NxNz < NxPz )
					fromRecalc = true;
				PxPz = Math.max( PxPz, fromOxelScale.PxNz );
				if ( fromOxelScale.PxNz < PxPz )
					fromRecalc = true;
			}
			if ( fromRecalc )
				fromOxel.flowInfo.flowScaling.recalculate( fromOxel );
		}
	}
	
	public function faceGet( $dir:int ):Point {
		var point:Point = new Point(1,1);
		if ( Globals.POSX == $dir ) {
			point.x = PxNz;
			point.y = PxPz
		}
		else if ( Globals.NEGX == $dir ) {
			point.x = NxNz;
			point.y = NxPz;
		}   
		else if ( Globals.POSZ == $dir ) {
			point.x = PxPz;
			point.y = NxPz
		}   
		else if ( Globals.NEGZ == $dir ) {
			point.x = PxNz;
			point.y = NxNz
		}
		return point;
	}
	
	public function toString():String 	{
		return "PxPz: " + PxPz + "  PxNz: " + PxNz + "  NxNz: " + NxNz + "  NxPz: " + NxPz;
	}
} // end of class FlowInfo
} // end of package
