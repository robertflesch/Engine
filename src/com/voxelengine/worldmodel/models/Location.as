/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.models 
{
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	
	import com.voxelengine.Log;
	
	public class Location
	{
		private static var _scratchVec:Vector3D 				= new Vector3D();
		private var _changed:Boolean 							= false;					// INSTANCE NOT EXPORTED
		private var _useOrigPosition:Boolean 					= false;					// Set via script

		private var _position:Vector3D 							= new Vector3D();			// toJSON
		private var _positionOrig:Vector3D 						= new Vector3D();			// toJSON
		private var _rotation:Vector3D 							= new Vector3D();			// toJSON
		private var _rotationOrig:Vector3D 							= new Vector3D();			// toJSON
		private var _rotations:Vector.<Vector3D> 				= new Vector.<Vector3D>(3); // INSTANCE NOT EXPORTED
		private var _positions:Vector.<Vector3D> 				= new Vector.<Vector3D>(3); // INSTANCE NOT EXPORTED
		private var _scale:Vector3D 							= new Vector3D(1, 1, 1);	// toJSON
		private var _scaleOrig:Vector3D 							= new Vector3D(1, 1, 1);	// toJSON
		private var _center:Vector3D 							= new Vector3D();			// INSTANCE NOT EXPORTED
		private var _centerNotScaled:Vector3D 					= new Vector3D();			// INSTANCE NOT EXPORTED
		private var _velocity:Vector3D 							= new Vector3D();			// INSTANCE NOT EXPORTED

		private var _modelMatrix:Matrix3D 						= new Matrix3D();			// INSTANCE NOT EXPORTED
		private var _worldMatrix:Matrix3D 						= new Matrix3D();			// INSTANCE NOT EXPORTED
		private var _invModelMatrix:Matrix3D 					= new Matrix3D();			// INSTANCE NOT EXPORTED
				
		public function get changed():Boolean 					{ return _changed; }
		[inline] public function set changed($val:Boolean):void			{ _changed = $val; }

		public function get useOrigPosition():Boolean 					{ return _useOrigPosition; }
		public function set useOrigPosition($val:Boolean):void			{ _useOrigPosition = $val; }

		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Center
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get center():Vector3D 					{ return _center };
		public function set center($val:Vector3D):void			{ centerSetComp( $val.x, $val.y, $val.z ); }			
		public function 	centerSetComp( $x:Number, $y:Number, $z:Number ):void { 
			changed = true;
			_centerNotScaled.setTo( $x, $y, $z ); 
			_center.setTo( _centerNotScaled.x * scale.x, _centerNotScaled.y * scale.y, _centerNotScaled.z * scale.z );
			//Log.out( "set center - scale: " + _scale + "  center: " + center + "  centerConst: " + _centerNotScaled );
		}
		public function get centerNotScaled():Vector3D 					{ return _centerNotScaled };
				
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Scale
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get scale():Vector3D 					{ return _scale };
		public function 	scaleSetComp( $x:Number, $y:Number, $z:Number ):void { 
			changed = true;
			//trace( "Location.scaleSetComp x: " + $x + " y: " + $y + " z: " + $z );
			_scale.setTo( $x, $y, $z ); 
			_center.setTo( _centerNotScaled.x * $x, _centerNotScaled.y * $y, _centerNotScaled.z * $z );
		}
		public function set scale($val:Vector3D):void 			{ 
			changed = true;
			//trace( "Location.scale x: " + $val.x + " y: " + $val.y + " z: " + $val.z );
			_scale.setTo( $val.x, $val.y, $val.z );
			_center.setTo( _centerNotScaled.x * $val.x, _centerNotScaled.y * $val.y, _centerNotScaled.z * $val.z );
			//Log.out( "set scale - scale: " + _scale + "  center: " + center + "  centerConst: " + _centerNotScaled );
		}
		public function scaleReset():void 	{
			//trace( "Location.scaleReset x: " + _scaleOrig.x + " y: " + _scaleOrig.y + " z: " + _scaleOrig.z );
			scaleSetComp( _scaleOrig.x, _scaleOrig.y, _scaleOrig.z );
		}
		public function scaleGetOriginal():Vector3D 	{ return _scaleOrig; }
				
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Rotation
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get rotationGet():Vector3D 				{ return _rotation; }
		public function 	rotationGetComp():Vector3D 				{ return _rotation; }
		public function set rotationSet($val:Vector3D):void 	{ rotationSetComp( $val.x, $val.y, $val.z ); }
		public function get rotationGetRadians():Vector3D 		{ return new Vector3D( _rotation.x * Math.PI / 180, _rotation.y * Math.PI / 180, _rotation.z * Math.PI / 180 ) };
		public function 	rotationSetComp( $x:Number, $y:Number, $z:Number ):void { 
			//Log.out( "PosAndRot rot: " + _rotation.x+" " +_rotation.y+" " +_rotation.z );
			// Copy old rotation
			changed = true;
			
			_rotations[2].setTo( _rotations[1].x, _rotations[1].y, _rotations[1].z );
			_rotations[1].setTo( _rotations[0].x, _rotations[0].y, _rotations[0].z );
			_rotations[0].setTo( _rotation.x,     _rotation.y,     _rotation.z );
			
			_rotation.setTo( $x % 360, $y % 360, $z % 360 ); 
		}
		public function rotationReset():void 	{ rotationSetComp( _rotationOrig.x, _rotationOrig.y, _rotationOrig.z ); }
		public function rotationGetOriginal():Vector3D 	{ return _rotationOrig; }
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Position - positions are in MODEL SPACE (ms)
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get positionGet():Vector3D 				{ return _position; }
		public function set positionSet( $val:Vector3D ):void 	{ positionSetComp( $val.x, $val.y, $val.z ); }
		public function 	positionSetComp( $x:Number, $y:Number, $z:Number ):void 
		{ 
			changed = true;
			
			_positions[2].setTo( _positions[1].x, _positions[1].y, _positions[1].z );
			_positions[1].setTo( _positions[0].x, _positions[0].y, _positions[0].z );
			_positions[0].setTo( _position.x,     _position.y,     _position.z );
			//trace( "Location.positionSetComp position: x: " + $x + "  y: " + $y + "  z: " + $z );
			
			_position.setTo( $x, $y, $z ); 
		}
		public function positionReset():void 	{ positionSetComp( _positionOrig.x, _positionOrig.y, _positionOrig.z ); }
		public function positionGetOriginal():Vector3D 	{ return _positionOrig; }
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Velocity
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get velocityGet():Vector3D 				{ return _velocity };
		public function set velocitySet( $val:Vector3D ):void 	{ velocitySetComp( $val.x, $val.y, $val.z ); }
		public function 	velocityReset():void 				{ velocitySetComp( 0, 0, 0 ); }
		public function 	velocityResetY():void				{ _velocity.y = 0;}
		public function 	velocityScaleBy( $val:Number ):void	{ _velocity.scaleBy( $val ); }
		public function 	velocitySetComp( $x:Number, $y:Number, $z:Number ):void {  _velocity.setTo( $x, $y, $z ); }
		public function 	velocityClip():void 
		{
			velocitySetComp( ( -0.005 < velocityGet.x && velocityGet.x < 0.005) ? 0 : velocityGet.x
			               , ( -0.005 < velocityGet.y && velocityGet.y < 0.005) ? 0 : velocityGet.y
						   , ( -0.005 < velocityGet.z && velocityGet.z < 0.005) ? 0 : velocityGet.z )
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		// Location functions
		////////////////////////////////////////////////////////////////////////////////////
		public function Location()
		{
			_positions[2] = new Vector3D();
			_positions[1] = new Vector3D();
			_positions[0] = new Vector3D();
			_rotations[2] = new Vector3D();
			_rotations[1] = new Vector3D();
			_rotations[0] = new Vector3D();
		}
		
		public function setTo( $val:Location ):void
		{
			positionSet = $val.positionGet;
			rotationSet = $val.rotationGet;
			velocitySet = $val.velocityGet;
			center.setTo( $val.center.x, $val.center.y, $val.center.z );
			_scale = $val._scale;
			//trace( "Location.setTo scale: " + _scale );

		}
		
		public function restoreOld( index:int = 1 ):void
		{
			//trace( "Location.restoreOld position["+index+"] position: " + _positions[index] );
			_position.setTo( _positions[index].x, _positions[index].y, _positions[index].z );
			_rotation.setTo( _rotations[index].x, _rotations[index].y, _rotations[index].z );
			changed = true;
		}
		
		public function nearEquals( $val:Location ):Boolean
		{
			if ( !positionGet.nearEquals( $val.positionGet, 0.01 ) )
				return false;
			if ( !rotationGet.nearEquals( $val.rotationGet, 0.01 ) )
				return false;
			return true;	
		}

		////////////////////////////////////////////////////////////////////////////////////
		// matrix ops
		////////////////////////////////////////////////////////////////////////////////////
		// dont recalculate unless it is needed
		// that is when ever it is access and the data in it has changed
		protected function recalculateMatrix( force:Boolean = false ):void
		{  
			if ( changed || force )
			{
				_modelMatrix.identity();
				//Log.out( "recalculateMatrix - scale: " + _scale + "  center: " + center + "  centerConst: " + _centerNotScaled );
				
				_modelMatrix.prependRotation( rotationGet.x, Vector3D.X_AXIS, _center );
				_modelMatrix.prependRotation( rotationGet.y,  Vector3D.Y_AXIS, _center );
				_modelMatrix.prependRotation( rotationGet.z, Vector3D.Z_AXIS, _center );

				_scratchVec.copyFrom( _position );
				_scratchVec.negate();
				_modelMatrix.prependTranslation( _scratchVec.x
											   , _scratchVec.y
											   , _scratchVec.z );

				_modelMatrix.appendScale( 1 / _scale.x, 1 / _scale.y, 1 / _scale.z );
				_invModelMatrix.copyFrom( _modelMatrix );
				_invModelMatrix.transpose();
												  
				_worldMatrix.copyFrom( _modelMatrix );
				_worldMatrix.invert();
				
				_changed = false;
			}
		}
		
		public function get worldSpaceMatrix():Matrix3D 		{ recalculateMatrix(); return _worldMatrix; }
		public function get modelMatrix():Matrix3D 				{ recalculateMatrix(); return _modelMatrix; }
		public function get invModelMatrix():Matrix3D 			{ return _invModelMatrix; }
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Look At
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function lookAtVector( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			// was using _modelMatrix, but I think that is wrong.
			return _invModelMatrix.deltaTransformVector( new Vector3D( 0, 0, -length ) );
		}
		
		public function lookDownVector( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return _modelMatrix.deltaTransformVector( new Vector3D( 0, length, 0 ) );
		}
		
		public function lookUpVector( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return _modelMatrix.deltaTransformVector( new Vector3D( 0, -length, 0 ) );
		}
		
		public function lookRightVector( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return _modelMatrix.deltaTransformVector( new Vector3D( length, 0, 0 ) );
		}
		
		public function lookBackVector( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return _modelMatrix.deltaTransformVector( new Vector3D( 0, 0, length ) );
		}

		public function placeAt( length:int ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			var newPos:Vector3D = _modelMatrix.deltaTransformVector( new Vector3D( 0, 0, length ) );
			//
			newPos = newPos.add( positionGet );
			return newPos;
		}
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// WorldToModel and ModelToWorld
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function worldToModel( v:Vector3D ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return _modelMatrix.transformVector( v );
		}
		
		public function modelToWorld( v:Vector3D ):Vector3D
		{
			if ( changed )
				recalculateMatrix();
			return worldSpaceMatrix.transformVector( v );
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// JSON initialization from JSON
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function setScaleInfo( $obj:Object ):void {
				if ( $obj.x && $obj.x > 0.001 )
					scale.x = $obj.x;
				if ( $obj.y && $obj.y > 0.001 )
					scale.y = $obj.y;
				if ( $obj.z && $obj.z > 0.001 )
					scale.z = $obj.z;
			_scaleOrig.setTo( scale.x, scale.y, scale.z );
			//Log.out( "Location.setScaleInfo - scale: " + _scale );
			changed = true;
		}
		
		public function setCenterInfo( $obj:Object ):void {
			centerSetComp( $obj.x, $obj.y, $obj.z );
		}
		
		public function setPositionInfo( $obj:Object ):void {
			if ( isNaN( $obj.x )|| isNaN( $obj.y ) || isNaN( $obj.z ) )
					return;
			positionSetComp( $obj.x, $obj.y, $obj.z );
			_positionOrig.setTo( _position.x, _position.y, _position.z );
		}
		
		public function setRotationInfo( $obj:Object ):void {
			rotationSetComp( $obj.x, $obj.y, $obj.z );
			_rotationOrig.setTo( _rotation.x, _rotation.y, _rotation.z );
		}
		
		public function fromObject( $obj:Object ):void {
			if ( $obj.location )
				setPositionInfo( $obj.location );
			if ( $obj.rotation )	
				setRotationInfo( $obj.rotation );
			if ( $obj.scale )
				setScaleInfo( $obj.scale );
			if ( $obj.center ) 
				setCenterInfo( $obj.center );
		}
		
		public function toObject():Object {
			var obj:Object = {};
		
			// Save original or current positions? would seem like current
			// why was I using original?
			if ( useOrigPosition )
				obj.location 			= vector3DToObject( _positionOrig );
			else
				obj.location 			= vector3DToObject( _position );

//Log.out( "Location.toObject _positionOrig: " + _positionOrig + "  _position: " + _position, Log.WARN )			
			if ( 0 < _rotationOrig.length ) {
				if ( useOrigPosition )
					obj.rotation = vector3DToObject(_rotationOrig);
				else
					obj.rotation = vector3DToObject(_rotation);
			}

			if ( 0 < centerNotScaled.length )
				obj.center 		= vector3DIntToObject( centerNotScaled );

			if ( 3 != _scaleOrig.lengthSquared ) {
				if ( useOrigPosition )
					obj.scale = vector3DToObject(_scaleOrig );
				else
					obj.scale = vector3DToObject(_scale);
			}
			
			return obj
		}
		
		private function vector3DToObject( $vec:Vector3D ):Object {
			return { x:$vec.x, y:$vec.y, z:$vec.z };
		}
		
		private function vector3DIntToObject( $vec:Vector3D ):Object {
			return { x:int($vec.x), y:int($vec.y), z:int($vec.z) };
		}
	}
}