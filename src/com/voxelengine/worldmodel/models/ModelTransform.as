/*==============================================================================
Copyright 2011-2013 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.geom.Vector3D;

import com.voxelengine.events.TransformEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.types.VoxelModel;

/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */

public class ModelTransform
{
	static public const INVALID:int 			= 0 	
	static public const POSITION:int 			= 1 	
	static public const POSITION_TO:int 		= 2
	static public const POSITION_REPEATING:int 	= 3
	static public const SCALE:int 				= 4		
	static public const ROTATION:int 			= 5    
	static public const ROTATE_TO:int 			= 6
	static public const ROTATION_REPEATING:int 	= 7
	static public const LIFE:int 				= 8
	static public const VELOCITY:int 			= 9
	
	static public const INFINITE_TIME:int 		= -1;
	
	static public const POSITION_STRING:String 				= "position"
	static public const POSITION_TO_STRING:String			= "position_to"
	static public const POSITION_REPEATING_STRING:String 	= "position_repeating"
	static public const SCALE_STRING:String 				= "scale"
	static public const ROTATION_STRING:String 				= "rotation"
	static public const ROTATE_TO_STRING:String 			= "rotate_to"
	static public const ROTATION_REPEATING_STRING:String 	= "rotation_repeating"
	static public const LIFE_STRING:String 					= "life"
	static public const VELOCITY_STRING:String 				= "velocity"
	
	private var _time:int = 0;            // in milliseconds
	private var _originalTime:Number = 0; // in milliseconds (NOW)
	private var _originalDelta:Vector3D = new Vector3D();
	private var _delta:Vector3D = new Vector3D();
	private var _transformTarget:Vector3D;
	private var _type:int;
	private var _name:String;
	private var _guid:String = "INVALID";
	private var _inverse:Boolean = false;  // REPEATING ROTATIONS change the sign on the delta every cycle.
	
	// these are dynamic values that change over the life of the animation
	private function get time():int 						{ return _time; }
	private function set time(val:int):void 				{ _time = val; }
	private function get delta():Vector3D 					{ return _delta; }
	private function set delta(val:Vector3D):void 			{ _delta = val; }
	private function get transformTarget():Vector3D 		{ return _transformTarget; }
	private function set transformTarget(val:Vector3D):void { _transformTarget = val; }
	
	public function get originalTime():int 					{ return _originalTime; }
	public function set originalTime(val:int):void 			{  _time = _originalTime = val; }
	public function get originalDelta():Vector3D 			{ return _originalDelta; }
	public function set originalDelta(val:Vector3D):void 	{ _delta = _originalDelta = val; }
	public function get type():int 							{ return _type; }
	public function set type(val:int):void 					{ _type = val; }
	public function get name():String 						{ return _name; }
	public function set name(val:String):void 				{ _name = val; }
	
	static public function typesList():Vector.<String> {
		var types:Vector.<String> = new Vector.<String>
		types.push( POSITION_STRING )
		types.push( POSITION_TO_STRING )		
		types.push( POSITION_REPEATING_STRING )
		types.push( SCALE_STRING )
		types.push( ROTATION_STRING )
		types.push( ROTATE_TO_STRING ) 		
		types.push( ROTATION_REPEATING_STRING )
		types.push( LIFE_STRING )	
		types.push( VELOCITY_STRING )
		return types
	}
	
	static public function defaultObject():ModelTransform {
		var obj:Object = { 	time : 1,
							delta: { x:0, y:0, z:0 },
							type: ModelTransform.ROTATION_REPEATING,
							name: "Default" }

		return new ModelTransform( obj.delta.x, obj.delta.y, obj.delta.z, obj.time, obj.type, obj.name );
	}
	
	public function ModelTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ) {
		//Log.out( "ModelTransform - "  + " type: " + $type + " x: " + $x + " y: " + $y + " z: " + $z + " time: " + $time + " name: " + $name, Log.WARN );
		
		_originalDelta.setTo( $x, $y, $z );
		_originalTime = $time;
		if ( 0 == $time )
			Log.out( "ModelTransform - No time defined name: " + $name + " x: " + $x + " y: " + $y + " z: " + $z, Log.ERROR );

		if ( 0 == $x && 0 == $y && 0 == $z && 0 == $time && ModelTransform.LIFE != $type )
			Log.out( "ModelTransform - No values defined", Log.ERROR );
		
		if ( 100 > $time && -1 != $time ) {
			Log.out( "ModelTransform - OLD TIME BEING USED: " + $name + " x: " + $x + " y: " + $y + " z: " + $z, Log.ERROR );
			$time = $time * 1000
		}

		name = $name;
		type = $type;
		if ( type == ModelTransform.SCALE )
		{
			_delta.x = ($x - 1)  / 1000;
			_delta.y = ($y - 1) / 1000;
			_delta.z = ($z - 1) / 1000;
		}
		else if ( ModelTransform.ROTATE_TO == type || ModelTransform.POSITION_TO == type )
		{
			_delta.x = $x;
			_delta.y = $y;
			_delta.z = $z;
		}
		else
		{
			if ( ModelTransform.INFINITE_TIME == $time ) {
				_delta.x = $x / 1000
				_delta.y = $y / 1000
				_delta.z = $z / 1000
			}
			else {
				_delta.x = $x / $time
				_delta.y = $y / $time
				_delta.z = $z / $time
			}
		}
		
		if ( ModelTransform.INFINITE_TIME == $time )
			time = ModelTransform.INFINITE_TIME;
		else
			time = $time
			
//			if ( ModelTransform.LIFE == type )
//				Log.out( "ModelTransform.constructor - data: " + toString() );	
	}
	
	// Animations use these as throw aways, when scaling animations
	public function clone( $val:Number ):ModelTransform {
		Log.out( "ModelTransform.clone - "  + " type: " + type + " x: " + _originalDelta.x + " y: " + _originalDelta.y + " z: " + _originalDelta.z
		       + " time: " + time + " name: " + name, Log.WARN );
		var mt:ModelTransform = new ModelTransform( _originalDelta.x
												  , _originalDelta.y
												  , _originalDelta.z
												  , _originalTime
												  , type
												  , name );
		mt._delta.setTo( _delta.x * $val, _delta.y * $val, _delta.z * $val );
//		mt._time = _time;
//		mt._originalTime = _originalTime;
//		Log.out( "ModelTransform.clone - "  + " type: " + type + " x: " + _originalDelta.x + " y: " + _originalDelta.y + " z: " + _originalDelta.z
//		       + " time: " + time + " name: " + name, Log.WARN );
		return mt;
	}

	public function assignToInstanceInfo( ii:InstanceInfo ):String {
		if ( ii )
		{
			if ( _guid != "INVALID" )
				Log.out( "ModelTransform.assignToInstanceInfo - Guid already assigned", Log.ERROR );
			_guid = Globals.getUID();
		}
		
		if  (  ModelTransform.POSITION == type 
			|| ModelTransform.POSITION_REPEATING == type )	 	
			transformTarget = ii.positionGet;
		else if (  ModelTransform.ROTATION == type
				|| ModelTransform.ROTATION_REPEATING == type )	
			transformTarget = ii.rotationGet;
		else if (  ModelTransform.ROTATE_TO == type )	
		{
			transformTarget = ii.rotationGet;
			// This one cant get its delta until it gets its transform target
			_delta.x = ( _delta.x - transformTarget.x ) / time;
			_delta.y = ( _delta.y - transformTarget.y ) / time;
			_delta.z = ( _delta.z - transformTarget.z ) / time;
		}
		else if (  ModelTransform.POSITION_TO == type )	
		{
			transformTarget = ii.positionGet;
			// This one cant get its delta until it gets its transform target
			_delta.x = ( _delta.x - transformTarget.x ) / time;
			_delta.y = ( _delta.y - transformTarget.y ) / time;
			_delta.z = ( _delta.z - transformTarget.z ) / time;
		}
		else if ( ModelTransform.SCALE == type )		transformTarget = ii.scale;
		else if ( ModelTransform.LIFE == type )			transformTarget = ii.life;
		else if ( ModelTransform.VELOCITY == type )		transformTarget = ii.velocityGet;
		
		return _guid;
	}
	
	public function modify( $referenceMt:ModelTransform, $val:Number ):void {
		_delta.setTo( $referenceMt._delta.x * $val, $referenceMt._delta.y * $val, $referenceMt._delta.z * $val );
		if ( _inverse )
			_delta.negate();
	}
	
	public function update( elapsedTimeMS:int, owner:VoxelModel ):Boolean {
		if ( 50 < elapsedTimeMS )
			Log.out( "ModelTransform.update - elapsedTimeMS: " + elapsedTimeMS );
			
		if ( null == transformTarget ) {
			Log.out( "ModelTransform.update - ERROR - No transfrom target OR assigned is false" );
			return true;
		}
		
		var channelRunTime:Number = 0;
		if ( _time > 0 || _time == INFINITE_TIME ) {
			// Translate channel active, update position
			if ( _time == INFINITE_TIME ) {
				channelRunTime = elapsedTimeMS;
			}
			else
			{
				// if no time is left, return the remaining time as run time.
				// if this is the object's life, removed it.
				if ( elapsedTimeMS >= _time ) {
					if ( ROTATION_REPEATING == type || POSITION_REPEATING == type ) {
						if ( ModelTransform.INFINITE_TIME == _originalTime )
							_time = ModelTransform.INFINITE_TIME;
						else
							_time = _originalTime
						
						_delta.negate();
						_inverse = !_inverse;
					}
					else {
						channelRunTime = _time;
						_time = 0;
						TransformEvent.dispatch( new TransformEvent( TransformEvent.ENDED, _guid, name ) );
					}
				}
				else {
					channelRunTime = elapsedTimeMS;
					_time -= elapsedTimeMS;
				}
			}
		}
		
		if ( 0 < channelRunTime ) {
			//Log.out( "ModelTransform.update - type: " + typeToString( type ) + "  tt: " + _transformTarget + " crt: " + channelRunTime + "  delta: " + _delta + " time: " + _time );
			if ( VELOCITY == type ) {
				var dr:Vector3D = owner.instanceInfo.worldSpaceMatrix.deltaTransformVector( new Vector3D(0, 1, -1) );

				_transformTarget.x += channelRunTime * _delta.x * dr.x;
				_transformTarget.y += channelRunTime * _delta.y * dr.y;
				_transformTarget.z += channelRunTime * _delta.z * dr.z;
				
				//Log.out( "ModelTransform.update - Velocity: " + _transformTarget );
			}
			else {
				if ( ROTATION == type ) {
					_transformTarget.x = _transformTarget.x % 360;
					_transformTarget.y = _transformTarget.y % 360;
					_transformTarget.z = _transformTarget.z % 360;
				}
				else {
					_transformTarget.x += channelRunTime * _delta.x;
					_transformTarget.y += channelRunTime * _delta.y;
					_transformTarget.z += channelRunTime * _delta.z;
				}
			}
		}

		// this was doing bad things
		//if ( 0 == _time && VELOCITY == type )
		//{
			// return velocity to original value
			//_transformTarget.x -= _delta.x * 1000 * _originalTime/1000;
			//_transformTarget.y -= _delta.y * 1000 * _originalTime/1000;
			//_transformTarget.z -= _delta.z * 1000 * _originalTime/1000;
			//_transformTarget.x = Math.round( _transformTarget.x );
			//_transformTarget.y = Math.round( _transformTarget.y );
			//_transformTarget.z = Math.round( _transformTarget.z );
			//Log.out( "ModelTransfrom.return velocity to original: " + _transformTarget.y )
		//}
		
		if ( 0 == _time )
			return true;
			
		return false;
	}
	
	public function toObject():Object {			
		var obj:Object = new Object();
		obj.time 	= _originalTime;
		obj.delta	= vector3DToObject( _originalDelta );
		obj.type 	= typeToString( _type );
		return obj
		
		function vector3DToObject( $vec:Vector3D ):Object {
			return { x:$vec.x, y:$vec.y, z:$vec.z };
		}
	}
	
	static public function stringToType( val:String ):int {
		if ( POSITION_STRING == val.toLowerCase() )
			return POSITION;
		if ( POSITION_TO_STRING == val.toLowerCase() )
			return POSITION_TO;
		if ( POSITION_REPEATING_STRING == val.toLowerCase() )
			return POSITION_REPEATING;
		else if ( SCALE_STRING == val.toLowerCase() )
			return SCALE;
		else if ( ROTATION_STRING == val.toLowerCase() )
			return ROTATION;
		else if ( ROTATE_TO_STRING == val.toLowerCase() )
			return ROTATE_TO;
		else if ( ROTATION_REPEATING_STRING == val.toLowerCase() )
			return ROTATION_REPEATING;
		else if ( LIFE_STRING == val.toLowerCase() )
			return LIFE;
		else if ( VELOCITY_STRING == val.toLowerCase() )
			return VELOCITY;
		else
			Log.out( "ModelTransform.stringToType - ERROR - type not found: " + val, Log.ERROR );
		return -1;
	}

	static public function typeToString( val:int ):String {
		if ( POSITION == val )
			return POSITION_STRING;
		if ( POSITION_TO == val )
			return POSITION_TO_STRING;
		if ( POSITION_REPEATING == val )
			return POSITION_REPEATING_STRING;
		else if ( SCALE == val )
			return SCALE_STRING;
		else if ( ROTATION == val )
			return ROTATION_STRING;
		else if ( ROTATE_TO == val )
			return ROTATE_TO_STRING;
		else if ( ROTATION_REPEATING == val )
			return ROTATION_REPEATING_STRING;
		else if ( LIFE == val )
			return LIFE_STRING;
		else if ( VELOCITY == val )
			return VELOCITY_STRING;
		else
			Log.out( "ModelTransform.typeToString - ERROR - type not found: " + val, Log.ERROR );
			
		return "Undefined";
	}
/*
	private function vectorToJSON( v:Vector3D ):String {  return JSON.stringify( {x:v.x, y:v.y, z:v.z} ); } 	

	public function getJSON():String {
		
		var outString:String = "{";
		outString += "\"delta\": " + vectorToJSON( _delta );
		outString += ",";
		outString += "\"time\": " + _time/1000;
		outString += ",";
		outString += "\"type\": ";
		outString += "\"" + typeToString( _type ) + "\"";
		//outString += ","; // Redundant
		//outString += "\"name\": ";
		//outString += "\"" + name + "\"";
		outString += "}";
		return outString;
	}
	*/
	public function toString():String { 
		return "{ delta: " +  _originalDelta + "  time: " + _originalTime + "  type: " + typeToString( _type ) + "  name: " + name + "}";
	} 			
	
	public function deltaAsString():String { 
		return "x: " +  _originalDelta.x + " y: " +  _originalDelta.y + " z: " +  _originalDelta.z + " "
	} 			
}
}