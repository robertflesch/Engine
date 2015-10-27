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
	private static const DEFAULT:uint 						= 0x006288ff;
	
	private static const FLOW_DOWN:uint 					= 0x000000ff;
	private static const FLOW_DOWN_MASK:uint 				= 0xffffff00;
	private static const FLOW_OUT:uint 						= 0x00000f00;
	private static const FLOW_OUT_MASK:uint 				= 0xfffff0ff;
	private static const FLOW_OUT_REF:uint 					= 0x0000f000;
	private static const FLOW_OUT_REF_MASK:uint 			= 0xffff0fff;
	
	private static const FLOW_FLOW_TYPE:uint 				= 0x000f0000;
	private static const FLOW_FLOW_TYPE_MASK:uint 			= 0xfff0ffff;
	
	private static const FLOW_FLOW_DIR:uint 				= 0x00f00000;
	private static const FLOW_FLOW_DIR_MASK:uint 			= 0xff0fffff;
	
	private static const FLOW_FLOW_CONTRIBUTE:uint			= 0xff000000;
	private static const FLOW_FLOW_CONTRIBUTE_MASK:uint		= 0x00ffffff;
	
	private static const FLOW_DOWN_OFFSET:uint				= 0;
	private static const FLOW_OUT_OFFSET:uint				= 8;
	private static const FLOW_OUT_REF_OFFSET:uint			= 12;
	private static const FLOW_TYPE_OFFSET:uint				= 16;
	private static const FLOW_DIR_OFFSET:uint				= 20;
	private static const FLOW_CONTRIBUTE_OFFSET:uint		= 24;

	public static const FLOW_TYPE_UNDEFINED:int				= 0;
	public static const FLOW_TYPE_MELT:int					= 1;
	public static const FLOW_TYPE_CONTINUOUS:int			= 2;
	public static const FLOW_TYPE_SPRING:int				= 3;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  _flowInfo function this is a bitwise data field. which holds flow type, CONTRIBUTE, count out and count down
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private var _data:uint 									= 0;                 
	private var _flowScaling:FlowScaling					= new FlowScaling();
	
	public 	function get out():int { return (_data & FLOW_OUT) >> FLOW_OUT_OFFSET; }
	public 	function set out($val:int):void { $val = $val << FLOW_OUT_OFFSET;  _data &= FLOW_OUT_MASK; _data = $val | _data; }
	public 	function get outRef():int { return (_data & FLOW_OUT_REF ) >> FLOW_OUT_REF_OFFSET; }
	public	function set outRef($val:int):void { $val = $val << FLOW_OUT_REF_OFFSET;  _data &= FLOW_OUT_REF_MASK; _data = $val | _data; }
	
	public 	function get down():int { return (_data & FLOW_DOWN) >> FLOW_DOWN_OFFSET; }
	public 	function set down($val:int):void { $val = $val << FLOW_DOWN_OFFSET; _data &= FLOW_DOWN_MASK; _data = $val | _data; }
	
	public 	function get type():int { return (_data & FLOW_FLOW_TYPE) >> FLOW_TYPE_OFFSET; }
	public 	function set type($val:int):void { 
		$val = $val << FLOW_TYPE_OFFSET;
		_data &= FLOW_FLOW_TYPE_MASK;
		_data = $val | _data; 
		if ( 0 == ( _data & FLOW_FLOW_TYPE_MASK  ) )
			Log.out( "FlowInfo.type - set to 0", Log.WARN )
	}
	
	public function isSource():Boolean { return outRef == out }

	public 	function get direction():int { return (_data & FLOW_FLOW_DIR) >> FLOW_DIR_OFFSET; }
	public 	function set direction( $val:int):void 
	{ 
		$val = $val << FLOW_DIR_OFFSET;
		_data &= FLOW_FLOW_DIR_MASK;
		_data = $val | _data;
		
		if ( Globals.ALL_DIRS == direction )
			return;
		else if ( Globals.POSY == direction || Globals.NEGY == direction ) {
			if ( 0 < down )
				downDec();
		}
		else {
			if ( 0 < out )
				outDec();
		}
	}
	
	//public 	function get contribute():int { return (_flowInfo & FLOW_FLOW_CONTRIBUTE) >> FLOW_CONTRIBUTE_OFFSET; }
	//public 	function set contribute($val:int):void { $val = $val << FLOW_CONTRIBUTE_OFFSET;  _flowInfo &= FLOW_FLOW_CONTRIBUTE_MASK; _flowInfo = $val | _flowInfo; }
	//public 	function contributeInc():void { var i:int = contribute; i++; contribute = i; }
	public 	function outInc():void { var i:int = out; i++; out = i; }
	public 	function outDec():void { var i:int = out; i--; out = i; }

	// Once we go down, all out values are reset
	public function downInc():void { var i:int = down; i++; down = i; out = outRef; }
	public function downDec():void { var i:int = down; i--; down = i; out = outRef; }
	
	public function get flowScaling():FlowScaling 	{ return _flowScaling; }
	//public function scale():Number 				{ return Math.max( 0.0625, ( out / outRef ) ); }	
	//public function scale():uint 				{ return Math.max( 1, ( out / outRef ) * 16 ); }  //	x/8
	public function scale():uint { return Math.max( 1, ( out / outRef ) * 16 ); }
	
	public function inheritFlowMax( $intersectingFlowInfo:FlowInfo ):void {
		if ( out < $intersectingFlowInfo.out )
			out = $intersectingFlowInfo.out
		if ( down < $intersectingFlowInfo.down )
			down = $intersectingFlowInfo.down
	}
	
	// This should really only be used by the flowInfoPool
	public function FlowInfo() {
		flowInfoRaw = DEFAULT
	}
	
	public function get flowInfoRaw():uint { return _data }
	public function set flowInfoRaw( val:uint ):void { 
		_data = val 
		if ( 0 == type )
			Log.out( "FlowInfo.flowInfoRaw - type: " + type );
	}
	
	public function reset( $oxel:Oxel = null ):void {
		direction = Globals.ALL_DIRS
		type = FLOW_TYPE_UNDEFINED
		out = 0
		outRef = 0
		down = 0
		flowScaling.reset( $oxel )
	}
	
	public function clone( isChild:Boolean = false ):FlowInfo {
		var fi:FlowInfo = FlowInfoPool.poolGet();
		fi.flowInfoRaw = flowInfoRaw;
		if ( isChild )
			out = out * 2;
		return fi;
	}
	
	public function copy( $rhs:FlowInfo ):void {
		flowInfoRaw = $rhs.flowInfoRaw
		//type 	= $rhs.type
		//outRef 	= $rhs.outRef
		//out 	= $rhs.outRef
		//down 	= $rhs.down
		//direction = $rhs.direction
	}
	
	public function fromJson( $flowJson:Object ):void
	{
		if ( 3 == $flowJson.length )
		{
			type = $flowJson[0];
			var outVal:int = $flowJson[1];
			if ( 15 < outVal ) // out is never more then 15
			{
				Log.out( "FlowInfo.fromJson - Out value is greater then 15, clipping it to 15: " + outVal );
				outVal = 15;
			}
			out =  outVal;
			outRef = outVal;
			down = $flowJson[2];
			direction = Globals.ALL_DIRS;
		}
		else
			Log.out( "FlowInfo.fromJson - INCORRECT NUMBER OF PARAMETERS, EXPECTED 3, GOT: " + $flowJson.length );
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeUnsignedInt( _data );
		//trace( "FlowInfo.toByteArray - " + toString() )
		$ba = flowScaling.toByteArray( $ba )
		return $ba;
	}
	
	public function fromByteArray( $version:int, $ba:ByteArray ):ByteArray {
		flowInfoRaw = $ba.readUnsignedInt();
		$ba = flowScaling.fromByteArray( $version, $ba )
		return $ba;
	}
	
	public function toString():String {
		return "FlowInfo - _data: " + _data.toString(16) + " type: " + type + " out: " + out + " outRef: " + outRef + " down: " + down  + " dir: " + direction
	}
} // end of class FlowInfo
} // end of package
