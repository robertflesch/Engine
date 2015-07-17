/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import flash.display3D.Context3D;
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	
	import com.voxelengine.GUI.actionBars.UserInventory;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ShipEvent;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.MouseKeyboardHandler;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class Beast extends ControllableVoxelModel 
	{
		static private const MIN_TURN_AMOUNT:Number = 0.02;
		
		// Trying to keep these numbers between 1 and 100
		static private var _climbRate:SecureNumber = new SecureNumber( 70 );
		static private var _moveSpeed:SecureNumber = new SecureNumber( 20 );
		static private var	_maxClimbAngle:SecureNumber = new SecureNumber( 45 );
		static private var _maxTurnRate:SecureNumber = new SecureNumber( 100 );
		static private var _stallSpeed:SecureNumber = new SecureNumber( 2 );
		
		static protected var _seatLocation:Vector3D =  new Vector3D( 8, 12, 13 );
		
		static protected    const DEFAULT_SPEED_X:Number		= 0.5;
		private var   		_speedMultiplier:Number 				= DEFAULT_SPEED_X;
		protected function get 	mSpeedMultiplier():Number 				{ return _speedMultiplier; }
		protected function set 	mSpeedMultiplier($value:Number):void	{ _speedMultiplier = $value; }

		static public function get mClimbRate():Number  				{ return _climbRate.val; }
		static public function set mClimbRate($value:Number):void  		{ _climbRate.val = $value; }
		static public function get mMoveSpeed():Number  				{ return _moveSpeed.val; }
		static public function set mMoveSpeed($value:Number):void  		{ _moveSpeed.val = $value; }
		static public function get mMaxClimbAngle():Number  			{ return _maxClimbAngle.val; }
		static public function set mMaxClimbAngle($value:Number):void  { _maxClimbAngle.val = $value; }
		static public function get mMaxTurnRate():Number  				{ return _maxTurnRate.val; }
		static public function set mMaxTurnRate($value:Number):void  	{ _maxTurnRate.val = $value; }
		static public function get mStallSpeed():Number 				{ return _stallSpeed.val; }
		static public function set mStallSpeed($value:Number):void		{ _stallSpeed.val = $value; }
		
		static protected 	const 	TAIL:String					= "TAIL";
		static protected 	const 	WING:String					= "WING";
		static protected 	const 	WING_TIP:String				= "WING_TIP";
		static protected 	const 	FOOT:String					= "FOOT";
		static protected 	const 	FALL:String					= "FALL";
		
		public function Beast( ii:InstanceInfo ) { 
			super( ii );
			inventoryBitmap = "beastToolbar.png";
		}
		
		override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
			super.init( $mi, $vmm );
			
			//MouseKeyboardHandler.backwardEnabled = false;
			
			instanceInfo.usesCollision = true;
			//usesGravity = true;
			collisionMarkers = true;
		}		

		static public function buildExportObject( obj:Object ):void {
			ControllableVoxelModel.buildExportObject( obj )
			obj.beast 					= new Object();
			obj.beast.moveSpeed 		= mMoveSpeed * 10000;
			obj.beast.maxTurnRate 		= mMaxTurnRate / 100;
			obj.beast.maxClimbAngle		= mMaxClimbAngle;
			obj.beast.climbRate 		= mClimbRate * 100;
			obj.beast.seatLocation 		= { x:int(_seatLocation.x), y:int(_seatLocation.y), z:int(_seatLocation.z) };
		}
		
		override protected function processClassJson():void {
			super.processClassJson();
			if ( modelInfo.dbo && modelInfo.dbo.beast )
			{
				var beastInfo:Object = modelInfo.dbo.beast;
				if ( null == beastInfo ) {
					Log.out( "Beast.processClassJson - beast section not found: " + modelInfo.dbo.toString(), Log.ERROR );
					return;
				}
				
				if ( beastInfo.moveSpeed)
					mMoveSpeed = beastInfo.moveSpeed/10000;
				else
					mMoveSpeed = mMoveSpeed/10000;
				
				if ( beastInfo.maxTurnRate )
					mMaxTurnRate = beastInfo.maxTurnRate * 100;
				else
					// This should be around 10,000
					mMaxTurnRate = mMaxTurnRate * 100;
				
				if ( beastInfo.maxClimbAngle )
					mMaxClimbAngle = beastInfo.maxClimbAngle;
				
				if ( beastInfo.climbRate )
					mClimbRate = beastInfo.climbRate/100;
				else
					mClimbRate = mClimbRate / 100;
					
				if ( beastInfo.seatLocation ) {
					if ( beastInfo.seatLocation is Object ) {
						Log.out( "Beast.processClassJson: " + beastInfo.seatLocation );
						_seatLocation.setTo( beastInfo.seatLocation.x, beastInfo.seatLocation.y, beastInfo.seatLocation.z );
					}
					else
						_seatLocation.setTo( 0, 0, 0 );
						//_seatLocation.setTo( beastInfo.seatLocation.x, beastInfo.seatLocation.y, beastInfo.seatLocation.z );
				}
				else
					_seatLocation.setTo( 0, 0, 0 );
			}
			else
				Log.out( "Beast.processClassJson - NO Beast Json INFO FOUND", Log.WARN );
		}
		
		//override protected function addClassJson():String {
			//var jsonString:String = super.addClassJson();
			//jsonString += ",";
			//jsonString += "\"beast\": { "
			//jsonString += "\"moveSpeed\" : " + (mMoveSpeed * 10000) + ",";
			//jsonString += "\"maxTurnRate\" : " + (mMaxTurnRate / 100) + ",";
			//jsonString += "\"maxClimbAngle\" : " + mMaxClimbAngle + ",";
			//jsonString += "\"climbRate\" : " + (mClimbRate * 100) + ",";
			//jsonString += "\"seatLocation\" : " + JSON.stringify( _seatLocation );
			//jsonString += "}";
			//return jsonString;
		//}
		
		
		override protected function collisionPointsAdd():void {
			// TO DO Should define this in meta data??? RSF or using extents?
			
			var sizeOxel:Number = oxel.gc.size() / 2;
			_ct.addCollisionPoint( new CollisionPoint( FALL, new Vector3D( sizeOxel, -16, 0 ) ) );
			_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( sizeOxel, -15, 0 ) ) ); // foot
			/*
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, -20 ) ) ); //beak
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, 65 ) ) ); // tail
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel * 2.5, sizeOxel ) ) ); //top/avatar -0 should I add this when mounted?
			
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 0, sizeOxel, sizeOxel ) ) ); // left side
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel * 2, sizeOxel, sizeOxel ) ) ); // right side
			/*
			// note if I added these in from children, then I could get postion from children each frame...
			_ct.addCollisionPoint( new CollisionPoint( WING_TIP, new Vector3D( -55, sizeOxel, sizeOxel ) ) ); // left wing tip
			_ct.addCollisionPoint( new CollisionPoint( WING_TIP, new Vector3D( 80, sizeOxel, sizeOxel ) ) ); // right wing tip
			_ct.addCollisionPoint( new CollisionPoint( WING, new Vector3D( -25, sizeOxel, sizeOxel ) ) ); // left wing
			_ct.addCollisionPoint( new CollisionPoint( WING, new Vector3D( 45, sizeOxel, sizeOxel ) ) ); // right wing
			*/
			//_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, -6, 0 ) ) ); // bottom
		}

		override protected function cameraAddLocations():void {
			camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 20, 0) );
			camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 20, 50) );
			camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 30, 80) );
			//camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT - 40, 50) );
			camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 40, 100) );
			camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 50, 250) );
		}
		
		override protected function collisionCheckNew( $elapsedTimeMS:Number, $loc:Location, $collisionCandidate:VoxelModel, $stepUpCheck:Boolean = false ):int {
			//Log.out( "ControllableVoxelModel.collisionCheckNew - ENTER" );
			// reset all the points to be in a non collided state
			if ( _ct.hasPoints() )
			{
				var wingTip:int = 0;
				var fall:int = 0;
				var foot:int = 0;
				var body:int = 0;
				var wing:int = 0;
				
				_ct.setValid();
				var points:Vector.<CollisionPoint> = _ct.collisionPoints();
				const LOOK_AHEAD:int = 10;
				var velocityScale:Number = $loc.velocityGet.z * LOOK_AHEAD;
				for each ( var cp:CollisionPoint in points )
				{
					if ( cp.scaled )
						cp.scale( velocityScale );
					// takes the CollisionPoint's point which is in model space, and puts it in world space
					var posWs:Vector3D = $loc.modelToWorld( cp.point );
					// pass in the world space coordinate to get back whether the oxel at the location is solid
					$collisionCandidate.isSolidAtWorldSpace( cp, posWs, MIN_COLLISION_GRAIN );
					// if collided, increment the count on that collision point set
					if ( true == cp.collided )
					{
						if ( FALL == cp.name ) fall++;
						else if ( FOOT == cp.name ) foot++;
						else if ( BODY == cp.name ) body++;
						else if ( WING_TIP == cp.name ) 
						{
							if ( !onSolidGround ) // ignore the wing points on the ground
								wingTip++;
						}
						else wing++;	
					}
				}
			}

			if ( !fall )
				onSolidGround = false;

			// only the point beneath the foot is touching
			if ( fall && !foot && !body )
			{
				//Log.out( "Beast.collsionCheckNew - Only fall point is true" );
				onSolidGround = true;
				$loc.velocityResetY();
			}
			// the foot is in a solid surface
			// get it out
			else if ( fall && foot && (!body || !wingTip || !wing) )
			{
				//Log.out( "Beast.collsionCheckNew - Fall and Foot point is true" );
				onSolidGround = true;
				$loc.velocityResetY();

//				if (  5 > $loc.velocityGet.y )
				{
					//if ( 5 > $loc.velocityGet.length )
					{
						//Log.out( "Beast.collsionCheckNew - OK LAND" );
						// So I can see a problem here, what if I come in diagonally, and one collision point is stuck in a wall
						// and the other 3 in the floor.
						var co:Oxel = points[0].oxel;
						var no:Oxel = co.neighbor( Globals.POSY );
						// TODO how to handle children in no
						if ( no != Globals.BAD_OXEL )
						{
							//Log.out( "Beast.collisionCheckNew - Adjusting foot position" );
							var msCoord:int = no.gc.getWorldCoordinate( Globals.AXIS_Y );
							var wsCoord:Vector3D = $collisionCandidate.modelToWorld( new Vector3D( 0, msCoord, 0 ) );
							$loc.positionSetComp( $loc.positionGet.x, wsCoord.y - points[0].point.y, $loc.positionGet.z );	
							return -1;
						}
					}
//					else
//						Log.out( "Beast.collsionCheckNew - MOVING TOO FAST TO LAND" );

				}
//				else
//					Log.out( "Beast.collsionCheckNew - FALLING TOO FAST TO LAND" );
					
				Log.out( "Beast.collisionCheckNew - Failed to adjust foot position" );
					
				
				return -1;
			}
			else if ( wingTip && !onSolidGround )
			{
				if ( points[0].collided )
				{
					Log.out( "Beast.collisionCheckNew - left wing TIP collided" );
					$loc.rotationSetComp( $loc.rotationGet.x,  $loc.rotationGet.y - 1, $loc.rotationGet.z )
					$loc.velocityScaleBy( 0.5 );
					return -1;
				}	
				else
				{
					Log.out( "Beast.collisionCheckNew - right wing TIP collided" );
					$loc.rotationSetComp( $loc.rotationGet.x,  $loc.rotationGet.y + 1, $loc.rotationGet.z )
					$loc.velocityScaleBy( 0.5 );
					return -1;
				}
				return 1;
				
			}
			else if ( wing && !onSolidGround )
				return 1;
			else if ( body )
				return 1;
				
			// return -1 success!
			return -1;
		}
		
		override public function update( $context:Context3D, $elapsedTimeMS:int):void {
			
			if ( this == VoxelModel.controlledModel )
				handleMouseMovement( $elapsedTimeMS );
			
			super.update( $context, $elapsedTimeMS );
		}
		
		private var _dy:Number = 0;
		override protected function handleMouseMovement( $elapsedTimeMS:int ):void {
			if ( 0 == Globals.openWindowCount && Globals.active && Globals.clicked ) 
			{
				var climbFactor:Number = ( mMaxClimbAngle + instanceInfo.rotationGet.x) / mMaxClimbAngle;
				var scaleFactor:Number = mClimbRate + climbFactor;
				// When you are climbing you can turn faster because you are going slower
				var effectiveTurnRate:Number = mMaxTurnRate * ( scaleFactor )
				Log.out( "Move Speed would be set to: " + mMoveSpeed * scaleFactor + "  instead setting to 0", Log.WARN );
				//instanceInfo.moveSpeed = mMoveSpeed * scaleFactor;
				instanceInfo.moveSpeed = 10;
				var dx:Number
				dx = MouseKeyboardHandler.getMouseYChange()/effectiveTurnRate;
				dx *= $elapsedTimeMS;
				if ( MIN_TURN_AMOUNT >= Math.abs(dx) )
					dx = 0;
					

				_dy = MouseKeyboardHandler.getMouseXChange()/effectiveTurnRate;
				_dy *= $elapsedTimeMS;
				if ( MIN_TURN_AMOUNT >= Math.abs(_dy) )
					_dy = 0;
				
				if ( onSolidGround )
				{
					instanceInfo.rotationGet.setTo( 0, instanceInfo.rotationGet.y + _dy, 0 );
				}
				else
				{
					instanceInfo.rotationSetComp( instanceInfo.rotationGet.x + dx, instanceInfo.rotationGet.y + _dy, instanceInfo.rotationGet.z );
					// This sets the max climb angle, different beast could have different climb angles
					if ( -mMaxClimbAngle > instanceInfo.rotationGet.x )
					{
						instanceInfo.rotationSetComp( -mMaxClimbAngle, instanceInfo.rotationGet.y + _dy, instanceInfo.rotationGet.z );
					}
				}

				camera.rotationSetComp( instanceInfo.rotationGet.x, instanceInfo.rotationGet.y, instanceInfo.rotationGet.z );
			}
		}
		
		private const _smoothingFactor:Number = 0.1;
		private var   _workingAverage:Number = 0;
		override public function draw( $mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void {
				
			var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
			viewMatrix.append( $mvp );
			
			if ( !onSolidGround )
			{
				// This add a turn angle to the beast without causing the Z rotation to change turn characteristics.
				_workingAverage = ( _dy * _smoothingFactor ) + ( _workingAverage * ( 1.0 - _smoothingFactor) )			
				if ( 1.5 < Math.abs( _workingAverage ) )
				{
					if ( 0 < _workingAverage )
						_workingAverage = 1.5;
					else
						_workingAverage = -1.5;
				}
				viewMatrix.appendRotation( _workingAverage * -20, Vector3D.Z_AXIS );
			}
			
			if ( oxel )
			{
				var selected:Boolean = VoxelModel.selectedModel == this ? true : false;
				modelInfo.draw( viewMatrix, this, $context, selected, $isChild, $alpha );
			}
			
			for each ( var vm:VoxelModel in modelInfo.children )
			{
				if ( vm && vm.complete )
					vm.draw( viewMatrix, $context, true, $alpha );
			}	
		}
		
		override public function updateVelocity( $elapsedTimeMS:int, $clipFactor:Number ):Boolean 
		{
			// TODO What should default behavoir be for a beast?
			return super.updateVelocity( $elapsedTimeMS, $clipFactor );
		}
		
		override protected function setAnimation():void	{
			throw new Error( "Beast.setAnimation - OVERRIDE THIS FUNCTION" );
		}

		override public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
			//Log.out( "Beast.takeControl - starting position: " + $vm.instanceInfo.positionGet );
			super.takeControl( $modelLosingControl );
			
			MouseKeyboardHandler.leftTurnEnabled = false;
			MouseKeyboardHandler.rightTurnEnabled = false;
			//MouseKeyboardHandler.mouseLookReset()
			// now we set where the avatar will attach to beast.
			$modelLosingControl.instanceInfo.positionSet = _seatLocation;
			$modelLosingControl.instanceInfo.rotationSet = this.instanceInfo.rotationGet;
			//Log.out( "Beast.takeControl - after position set: " + $vm.instanceInfo.positionGet );
			Globals.g_app.addEventListener( ShipEvent.THROTTLE_CHANGED, throttleEvent );
			instanceInfo.usesCollision = true;
			camera.index = 2;	
		}
	
		override public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void {
			super.loseControl( $modelDetaching );
			MouseKeyboardHandler.leftTurnEnabled = true;
			MouseKeyboardHandler.rightTurnEnabled = true;
			// TODO reimplement in handler
			//MouseKeyboardHandler.backwardEnabled = true;
			$modelDetaching.instanceInfo.positionSetComp( $modelDetaching.instanceInfo.positionGet.x, $modelDetaching.instanceInfo.positionGet.y + _seatLocation.y, $modelDetaching.instanceInfo.positionGet.z );
			//$vm.instanceInfo.rotationSet = this.instanceInfo.rotationGet;
			$modelDetaching.instanceInfo.rotationSetComp( 0, instanceInfo.rotationGet.y, 0 );
			Globals.g_app.removeEventListener( ShipEvent.THROTTLE_CHANGED, throttleEvent );
			instanceInfo.usesCollision = false;
		}
	}
}
