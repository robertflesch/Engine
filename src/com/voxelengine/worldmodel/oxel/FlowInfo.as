/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
	import com.voxelengine.pools.FlowInfoPool;
	import flash.utils.ByteArray;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
/**
 * ...
 * @author Robert Flesch RSF Oxel - An OctTree / Voxel - model
 */
public class FlowInfo
{
	private static const FLOW_DOWN:uint 					= 0x000000ff;
	private static const FLOW_DOWN_MASK:uint 				= 0xffffff00;
	private static const FLOW_OUT:uint 						= 0x0000ff00;
	private static const FLOW_OUT_MASK:uint 				= 0xffff00ff;

	private static const FLOW_FLOW_TYPE:uint 				= 0x000f0000;
	private static const FLOW_FLOW_TYPE_MASK:uint 			= 0xfff0ffff;
	
	private static const FLOW_FLOW_DIR:uint 				= 0x00f00000;
	private static const FLOW_FLOW_DIR_MASK:uint 			= 0xff0fffff;
	
	private static const FLOW_DOWN_REF:uint					= 0xff000000;
	private static const FLOW_DOWN_REF_MASK:uint			= 0x00ffffff; // reused out mask here
	
	private static const FLOW_DOWN_OFFSET:uint				= 0;
	private static const FLOW_OUT_OFFSET:uint				= 8;
	private static const FLOW_TYPE_OFFSET:uint				= 16;
	private static const FLOW_DIR_OFFSET:uint				= 20;
	private static const FLOW_DOWN_REF_OFFSET:uint			= 24;

	/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 * FLOW FUNCTIONS
	 * three different kinds of flow
	 * 1) pressurized flow, $gc unlimited oxels are produced (rate limited?), this could fill a cavity then go over the top
	 * 2) continuous gravity flow, a spring for example, this flow always goes downhill, but doesnt run out
	 * 3) limited flow, like a bucket of water being poured out, this has a set number of oxels.
	 *
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
	public static const FLOW_TYPE_UNDEFINED:int				= 0;
	public static const FLOW_TYPE_MELT:int					= 1;
	public static const FLOW_TYPE_CONTINUOUS:int			= 2;
	public static const FLOW_TYPE_SPRING:int				= 3;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  _data is a bitwise data field. which holds flow type, direction, count out and count down
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private var _data:uint 									= 0;                 
	private var _flowScaling:FlowScaling					= new FlowScaling();
	
	// using out in a different way now
	private 	function get out():int { return (_data & FLOW_OUT) >> FLOW_OUT_OFFSET; }
	private 	function set out($val:int):void { $val = $val << FLOW_OUT_OFFSET;  _data &= FLOW_OUT_MASK; _data |= $val;  }
	public 	function     outInc( $val:uint ):void { var i:int = out; i += $val; out = i; }
	public 	function     outDec( $val:uint ):void { var i:int = out; i -= $val;  0 > i ? out = 0 : out = i; }
	
	// outRef is the max possible out values
	public 	function get downRef():int { return (_data & FLOW_DOWN_REF ) >> FLOW_DOWN_REF_OFFSET; }
	private	function     downRefSet($val:int):void { $val = $val << FLOW_DOWN_REF_OFFSET;  _data &= FLOW_DOWN_REF_MASK; _data |= $val;	}
	
	public 	function get down():int { return (_data & FLOW_DOWN) >> FLOW_DOWN_OFFSET; }
	public 	function set down($val:int):void { 
		$val = $val << FLOW_DOWN_OFFSET;
		_data &= FLOW_DOWN_MASK;
		_data |= $val; 	 
	}
	// Once we go down, all out values are reset
	public function      downInc( $val:uint ):void { var i:int = down; i += $val; down = i; /*out = outRef;*/ }
	public function      downDec( $val:uint ):void { var i:int = down; i -= $val; 0 > i ? down = 0 : down = i; /*out = outRef;*/ }
	
	public 	function get type():int { return (_data & FLOW_FLOW_TYPE) >> FLOW_TYPE_OFFSET; }
	public 	function set type($val:int):void { 
		$val = $val << FLOW_TYPE_OFFSET;
		_data &= FLOW_FLOW_TYPE_MASK;
		_data = $val | _data; 
	}
	
	public function isSource():Boolean { return _flowScaling.min() == 16 || _flowScaling.min() == 15 }

	public 	function get direction():int { return (_data & FLOW_FLOW_DIR) >> FLOW_DIR_OFFSET; }
	public 	function set direction( $val:int ):void  { 
		$val = $val << FLOW_DIR_OFFSET;
		_data &= FLOW_FLOW_DIR_MASK;
		_data = $val | _data;
	}
	
	// This should really only be used by the flowInfoPool
	public function FlowInfo():void {
		_data = 0
	}
	
	public function childGet( $child:Oxel ):void {
		$child.flowInfo = FlowInfoPool.poolGet()
		$child.flowInfo.copyToChild( this )
		_flowScaling.childGetScaleAndType( $child, $child.flowInfo.flowScaling )
	}

	public function copyToChild( $rhs:FlowInfo ):void {
		type = $rhs.type
		downRefSet( $rhs.downRef )
		down = $rhs.down
		direction = $rhs.direction

		// if its top grain, reduce down by half of unit value
		// need to do for out too, screw it!
		//if ( $child.gc.grainY % 2 )
		//	downInc( $child.gc.size() / Globals.UNITS_PER_METER) * 2 )
	}
	
	public function copy( $rhs:FlowInfo ):void {
		_data = $rhs._data
			
		flowScaling.copy( $rhs.flowScaling )
	}
		
	public 	function changeType( $stepSize:uint ):Boolean  { 
		if ( down < $stepSize )
			return true
		else if ( down < $stepSize * 2 )
			return Math.random() < 0.80
		else if ( down < $stepSize * 3 )
			return Math.random() < 0.5
		else if ( down < $stepSize * 4 )
			return Math.random() < 0.20
		return false	
	}
	public 	function directionSetAndDecrement( $dir:int, $stepSize:uint ):void  { 
		direction = $dir
		
		if ( Globals.ALL_DIRS == direction )
			return;
		else if ( Globals.POSY == direction || Globals.NEGY == direction ) {
			if ( 0 < down ) {
				if ( down < $stepSize )
					down = 0
				else
					downDec( $stepSize );
				
				out = 0
			}
		}
		else {
			// reset down value when we go out, like we reset out when we go down.
			down = downRef
			flowScaling.setToZero()
			out = out + 1
		}
		//Log.out( "FlowInfo.dirAndSet - out: " + out + "  oxelSize: " + $stepSize );
	}
	
	public function get flowScaling():FlowScaling 	{ return _flowScaling; }

	public function inheritFlowMax( $intersectingFlowInfo:FlowInfo ):void {
		if ( down < $intersectingFlowInfo.down )
			down = $intersectingFlowInfo.down
	}
	
	public function reset( $oxel:Oxel = null ):void {
		_data = 0
		flowScaling.reset( $oxel )
	}
	
	public function initialize( isChild:Boolean, $sourceOxel:Oxel  ):FlowInfo {
		var fi:FlowInfo = FlowInfoPool.poolGet()
		fi.copy( this )
		return fi
	}
	
	public function fromJson( $flowJson:Object ):void {
		if ( 3 <= $flowJson.length )
		{
			type = $flowJson[0];
			var outVal:int = $flowJson[1];
			if ( 15 < outVal ) { // out is never more then 15
				Log.out( "FlowInfo.fromJson - Out value is greater then 15, clipping it to 15: " + outVal, Log.WARN );
				outVal = 15;
			}
//			out =  ( outVal * 4);
//			outRefSet( outVal * 4);
			var downVal:int = $flowJson[2];
			if ( 63 < downVal ) { // down is never more then 63
				Log.out( "FlowInfo.downVal - down value is greater then 63, clipping it to 63: " + downVal, Log.WARN );
				downVal = 63;
			}
			down = downVal * 4;
			downRefSet( downVal * 4);
			direction = Globals.ALL_DIRS;
		}
		else
			Log.out( "FlowInfo.fromJson - INCORRECT NUMBER OF PARAMETERS, EXPECTED 3, GOT: " + $flowJson.length, Log.WARN );
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeUnsignedInt( _data );
		//trace( "FlowInfo.toByteArray - " + toString() )
		$ba = flowScaling.toByteArray( $ba )
		return $ba;
	}
	
	public function fromByteArray( $version:int, $ba:ByteArray ):ByteArray {
		_data = $ba.readUnsignedInt();
		$ba = flowScaling.fromByteArray( $version, $ba )
		return $ba;
	}
	
	public function toString():String {
		return "FlowInfo - _data: " + _data.toString(16) + " type: " + type + " down: " + down  + " dir: " + direction
	}
} // end of class FlowInfo
} // end of package
