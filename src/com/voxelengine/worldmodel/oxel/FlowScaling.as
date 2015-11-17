/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.TypeInfo;
/**
 * ...
 * @author Robert Flesch 
 */
public class FlowScaling
{
	private static var _s_flowScaling:FlowScaling = new FlowScaling() 
	private const DEFAULT_TOTAL_SCALE:uint = 0xffffffff;
	
	private 		var _calculated:Boolean = false
	public function get calculated():Boolean { return _calculated; }
	
	// has scaling for this oxel be calcualted
	private var _data:uint = DEFAULT_TOTAL_SCALE;
	public function get PxPz():uint { return ((_data  & 0x0000000f)); }
	public function get PxNz():uint { return ((_data  & 0x000000f0) >> 4 ); }
	public function get NxNz():uint { return ((_data  & 0x00000f00) >> 8 ); }
	public function get NxPz():uint { return ((_data  & 0x0000f000) >> 12 ); }
	
	// The quads needs this as 1 to 16, not 0 to 15
	public function get QuadPxPz():uint { return PxPz + 1 }
	public function get QuadPxNz():uint { return PxNz + 1 }
	public function get QuadNxNz():uint { return NxNz + 1 }
	public function get QuadNxPz():uint { return NxPz + 1 }
	
	//public function set PxPz( value:uint ):void { _data = ((_data & 0xfffffff0) | ( value )); }
	//public function set PxNz( value:uint ):void { _data = ((_data & 0xffffff0f) | (( value ) << 4) ); }
	//public function set NxNz( value:uint ):void { _data = ((_data & 0xfffff0ff) | (( value ) << 8) ); }
	//public function set NxPz( value:uint ):void { _data = ((_data & 0xffff0fff) | (( value ) << 12) ); }

	public function set PxPz( value:uint ):void { 
		if ( 15 < value )
			Log.out( "FlowScaling.PxPz PAST MAX: " + value, Log.WARN )
		_data = ((_data & 0xfffffff0) | ( value )); }
	public function set PxNz( value:uint ):void { 
		if ( 15 < value )
			Log.out( "FlowScaling.PxNz PAST MAX: " + value, Log.WARN )
		_data = ((_data & 0xffffff0f) | (( value ) << 4) ); }
	public function set NxNz( value:uint ):void { 
		if ( 15 < value )
			Log.out( "FlowScaling.NxNz PAST MAX: " + value, Log.WARN )
		_data = ((_data & 0xfffff0ff) | (( value ) << 8) ); }
	public function set NxPz( value:uint ):void { 
		if ( 15 < value )
			Log.out( "FlowScaling.NxPz PAST MAX: " + value, Log.WARN )
		_data = ((_data & 0xffff0fff) | (( value ) << 12) ); }
	
	/*
	 *               _____Nz_____
	 *              |            | 
	 *              |            | 
	 *              |            |
	 *              |NxPz    PxPz|
	 *  ____________|____________|____________
	 * |            |            |            |
	 * |        PxNz|NxNz    PxNz|NxNz        |
	 * Nx           |            |           Px
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
	public function has():Boolean { return ( _data != DEFAULT_TOTAL_SCALE ) }
	
	public function toByteArray( $ba:ByteArray ):ByteArray {
		
		$ba.writeUnsignedInt( _data );
		return $ba;
	}
	
	public function copy( $toBeCopied:FlowScaling ):void {
		_data = $toBeCopied._data
	}
	
	public function max():uint {
		return Math.max( Math.max( PxPz, PxNz ), Math.max( NxNz, NxPz ) )
	}
	
	public function min():uint {
		return Math.min( Math.min( PxPz, PxNz ), Math.min( NxNz, NxPz ) )
	}

	public function fromByteArray( $version:int, $ba:ByteArray ):ByteArray {
		// No need to handle versions yet
		if ( Globals.VERSION_004 == $version || Globals.VERSION_003 == $version ) {
			PxPz = rnd( $ba.readFloat() );
			PxNz = rnd( $ba.readFloat() );
			NxNz = rnd( $ba.readFloat() );
			NxPz = rnd( $ba.readFloat() );
		}
		else if ( Globals.VERSION_004 <= $version  ) {
			_data = $ba.readUnsignedInt();
		}
		else {
			Log.out( "FlowSacaling.fromByteArray - The version of data is not handled", Log.WARN )
			_data = $ba.readUnsignedInt();
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
	public function reset( $oxel:Oxel = null, $calculated:Boolean = false ):void	{
		//Log.out( "FlowScaling.reset oxel: " + toString() );
		// This differs from setToDefault in the set
		_calculated = false;
		// first reset this oxels scaling
		if ( has() ) {
			_data = DEFAULT_TOTAL_SCALE
			if ( $oxel )
				$oxel.rebuildAll();
		}
	}
	
	public function neighborsRecalc( $oxel:Oxel, $propgateMaxs:Boolean ):void	{
		// now check to see if we need to reset the scaling of our neighbors
		for each ( var dir:int in Globals.horizontalDirections ) {
			var fromOxel:Oxel = $oxel.neighbor( dir );
			if ( Globals.BAD_OXEL == fromOxel )
				continue;
			if ( fromOxel.type == $oxel.type && null != fromOxel.flowInfo ) {
				if ( $propgateMaxs )
					fromOxel.flowInfo.inheritFlowMax( $oxel.flowInfo )
				fromOxel.flowInfo.flowScaling.recalculate( fromOxel )
			}
		}
	}
	
	
	public function recalculate( $oxel:Oxel ):void	{
		if ( !has() )
			return;
			
		//Log.out( "FlowScaling.recalculate was: " + toString() );
		
		_calculated = false;
		calculate( $oxel );
		$oxel.rebuildAll();
		//Log.out( "FlowScaling.recalculate is: " + toString() );
	}
	
	private static const CORNER_MIN:Number = 0;
	public function calculate( $oxel:Oxel ):void	{
		if ( _calculated )
			return;
	
		//Log.out( "FlowScaling.calculate was: " + toString() + " oxel: " + toString() );
		_calculated = true;
		
		// The origin of the flow should never scale.
		if ( $oxel.flowInfo.isSource() )
			return
		// set these to a minimum level, so that their influence for the other corners can be felt
		_data = 0x00000000;
		

		for each ( var horizontalDir:int in Globals.horizontalDirections )
			grabNeighborInfluences( $oxel, horizontalDir );
		
		//Log.out( "FlowScaling.calculate after grabNeighborInfluences: " + toString() );
		// if these corners have not been influenced by another vert
		// set them to scale
		const fallRatePerMeter:uint = 2
		const amountToFall:uint = fallRatePerMeter * $oxel.gc.size() / Globals.UNITS_PER_METER
		if ( max() > amountToFall ) {
			if ( CORNER_MIN == PxPz )
				PxPz = max() - amountToFall
			if ( CORNER_MIN == PxNz )
				PxNz = max() - amountToFall
			if ( CORNER_MIN == NxNz )
				NxNz = max() - amountToFall
			if ( CORNER_MIN == NxPz )
				NxPz = max() - amountToFall
		}
		//Log.out( "FlowScaling.calculate is: " + toString() + " oxel: " + toString() );
	}
		
	// This currently only works for same sized neighbors.
	private function grabNeighborInfluences( $oxel:Oxel, $dir:int ):void {
		
		var fromOxel:Oxel = $oxel.neighbor( Oxel.face_get_opposite( $dir ) );
		if ( Globals.BAD_OXEL == fromOxel )
			return;
		var fromOxelScale:FlowScaling
		if ( TypeInfo.typeInfo[fromOxel.type].flowable && fromOxel.flowInfo && fromOxel.flowInfo.flowScaling && $oxel.flowInfo.flowScaling ) {
			
			// only accounts for one level of difference
			if ( $oxel.gc.grain < fromOxel.gc.grain && fromOxel.flowInfo ) {
				// calculate GC of opposite oxel on face
				var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound )
				gct.copyFrom( $oxel.gc )
				gct.move( $dir )
				var iDOpposite:uint = Oxel.childIdOpposite( Oxel.face_get_opposite( $dir ), $oxel.gc.childId()  )
				// this gets gets a copy of the virtual child in that position
				childGetScale( iDOpposite, fromOxel.flowInfo.flowScaling, _s_flowScaling )			
				GrainCursorPool.poolDispose( gct )
				fromOxelScale = _s_flowScaling
			}
			else
				fromOxelScale = fromOxel.flowInfo.flowScaling;
			
				
			var fromRecalc:Boolean = false;
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
			else if ( Globals.POSY == $dir )
			{
				reset()
				fromOxel.quadsDeleteAll()
				fromRecalc = true;
			}
			//if ( fromRecalc )
			//	fromOxel.flowInfo.flowScaling.recalculate( fromOxel );
		}
	}
	
	public function faceGet( $dir:int ):Point {
		var point:Point = new Point(1,1);
		if ( Globals.POSX == $dir ) {
			point.x = QuadPxNz;
			point.y = QuadPxPz
		}
		else if ( Globals.NEGX == $dir ) {
			point.x = QuadNxNz;
			point.y = QuadNxPz;
		}   
		else if ( Globals.POSZ == $dir ) {
			point.x = QuadPxPz;
			point.y = QuadNxPz
		}   
		else if ( Globals.NEGZ == $dir ) {
			point.x = QuadPxNz;
			point.y = QuadNxNz
		}
		return point;
	}
	
	public function toString():String 	{
		return "PxPz: " + PxPz + "  PxNz: " + PxNz + "  NxNz: " + NxNz + "  NxPz: " + NxPz;
	}
	
/*
	 *               _____Nz_____
	 *              |            | 
	 *              |            | 
	 *              |            |
	 *              |NxPz    PxPz|
	 *  ____________|____________|____________
	 * |            |            |            |
	 * |        PxNz|NxNz    PxNz|NxNz        |
	 * Nx           |            |           Px
	 * |        PxPz|NxPz    PxPz|NxPz        |
	 * |____________|____________|____________|
	 *              |            |
	 *              |NxNz    PxNz|
	 *              |            |
	 *              |            |
	 *              |_____Pz_____|
	 * 
	 */	
	
	public function childGetScaleAndType( $child:Oxel, childFS:FlowScaling ):void {
		// so evaluate scaling of parent
		// remember that scaling is relative to the size of the oxel
		// and that some of the oxel might become AIR if scaling is low.
		
		var childID:uint = $child.gc.childId()
		
		childGetScale( childID, this, $child.flowInfo.flowScaling )
		if ( 0 == childFS.max() )
			$child.type = TypeInfo.AIR
		
		Log.out( "FlowScaling.childGetScaleAndType - childID: " + childID + "  childFS: " + childFS.toString(), Log.WARN )
	}
	
	static private function childGetScale( $childID:uint, $pfs:FlowScaling, $childFS:FlowScaling ):void {
		// so evaluate scaling of parent
		// remember that scaling is relative to the size of the oxel
		// and that some of the oxel might become AIR if scaling is low.
		
		if ( 0 == $childID ) { // b000
			$childFS.NxNz = Math.min( 15, ($pfs.NxNz * 2 + 1) )
			$childFS.PxNz = Math.min( 15, ($pfs.NxNz + $pfs.PxNz  + 1 ) )
			$childFS.PxPz = Math.min( 15, ($pfs.NxNz + $pfs.PxPz + 1) )
			$childFS.NxPz = Math.min( 15, ($pfs.NxPz + $pfs.NxNz  + 1) )
		}
		else if ( 1 == $childID )	{ // b100
			$childFS.NxNz = Math.min( 15, ($pfs.NxNz + $pfs.PxNz + 1) )
			$childFS.PxNz = Math.min( 15, ($pfs.PxNz * 2 + 1) )
			$childFS.PxPz = Math.min( 15, ($pfs.PxNz + $pfs.PxPz + 1) )
			$childFS.NxPz = Math.min( 15, ($pfs.NxNz + $pfs.PxPz + 1) )
		}
		else if ( 2 == $childID )	{ // b010
			$childFS.NxNz = Math.max( 0, (($pfs.NxNz - 8) * 2 + 1) )
			$childFS.PxNz = Math.max( 0, ($pfs.NxNz + $pfs.PxNz - 15) )
			$childFS.PxPz = Math.max( 0, ($pfs.NxNz + $pfs.PxPz - 15) )
			$childFS.NxPz = Math.max( 0, ($pfs.NxPz + $pfs.NxNz - 15) )
		}
		else if ( 3 == $childID ) { // b110
			$childFS.NxNz = Math.max( 0, $pfs.NxNz + $pfs.PxNz - 15 )
			$childFS.PxNz = Math.max( 0, (($pfs.PxNz - 8) * 2 + 1) )
			$childFS.PxPz = Math.max( 0, $pfs.PxNz + $pfs.PxPz - 15 )
			$childFS.NxPz = Math.max( 0, $pfs.NxNz + $pfs.PxPz - 15 )
		}
		else if ( 4 == $childID )	{ // b001
			$childFS.NxNz = Math.min( 15, ($pfs.NxNz + $pfs.NxPz + 1) )
			$childFS.PxNz = Math.min( 15, ($pfs.NxNz + $pfs.PxPz + 1) )
			$childFS.PxPz = Math.min( 15, ($pfs.NxPz + $pfs.PxPz + 1) )
			$childFS.NxPz = Math.min( 15, ($pfs.NxPz  * 2 + 1) )
		}
		else if ( 5 == $childID )	{ // b101
			$childFS.NxNz = Math.min( 15, ($pfs.NxNz + $pfs.PxPz + 1) )
			$childFS.PxNz = Math.min( 15, ($pfs.PxNz + $pfs.PxPz + 1) )
			$childFS.PxPz = Math.min( 15, (($pfs.PxPz * 2) + 1) )
			$childFS.NxPz = Math.min( 15, ($pfs.NxPz + $pfs.PxPz + 1) )
		}
		else if ( 6 == $childID )	{ // b011
			$childFS.NxNz = Math.max( 0, ($pfs.NxNz + $pfs.NxPz - 15) )
			$childFS.PxNz = Math.max( 0, ($pfs.NxNz + $pfs.PxPz - 15) )
			$childFS.PxPz = Math.max( 0, ($pfs.NxPz + $pfs.PxPz - 15) )
			$childFS.NxPz = Math.max( 0, (($pfs.NxPz - 8) * 2 + 1) )
		}
		else if ( 7 == $childID )	{ // b111
			$childFS.NxNz = Math.max( 0, ($pfs.NxNz + $pfs.PxPz - 15) )
			$childFS.PxNz = Math.max( 0, ($pfs.PxNz + $pfs.PxPz - 15) )
			$childFS.PxPz = Math.max( 0, (($pfs.PxPz - 8) * 2 + 1) )
			$childFS.NxPz = Math.max( 0, ($pfs.NxPz + $pfs.PxPz - 15) )
		}	
		
		Log.out( "FlowScaling.childGetScale - childID: " + $childID + "  childFS: " + $childFS.toString(), Log.WARN )
	}
	
	static public function scaleTopFlowFace( $oxelToScale:Oxel ):void {
		var fs:FlowScaling = $oxelToScale.flowInfo.flowScaling
		if ( !fs.has() ) {
			var newScale:int = 15 // 15 is max
			if ( 5 == $oxelToScale.gc.grain )
				newScale = 14
			else if ( 4 == $oxelToScale.gc.grain )
				newScale = 13
			else if ( 3 == $oxelToScale.gc.grain )
				newScale = 11
			else if ( 2 == $oxelToScale.gc.grain )
				newScale = 7
				
			fs.NxNz = newScale
 			fs.NxPz = newScale
			fs.PxNz = newScale
			fs.PxPz = newScale
		}
		//Log.out( "FlowScaling.scaleTopFlowFace - flowScale: " + fs.toString(), Log.WARN )
	}
} // end of class FlowInfo
} // end of package
