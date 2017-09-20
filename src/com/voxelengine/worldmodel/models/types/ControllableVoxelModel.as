/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.Globals;

import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.utils.getTimer;
import flash.geom.Matrix3D;

import flash.events.KeyboardEvent;


import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.*;
import com.voxelengine.events.CollisionEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ShipEvent;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.events.CursorSizeEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.InventoryInterfaceEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.oxel.GrainIntersection;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;


/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class ControllableVoxelModel extends VoxelModel 
{
	static protected const SHIP_VELOCITY:String 			= "velocity";
	static protected const SHIP_ALTITUDE:String 			= "altitude";
	static protected const SHIP_ROTATION:String 			= "rotation";
	static protected const MIN_COLLISION_GRAIN:int 			= 2;
	static public 	const 	BODY:String						= "BODY";
	static protected    const DEFAULT_CLIP_VELOCITY:int		= 95;
	static protected    const DEFAULT_FALL_RATE:int			= 5;
	static protected    const DEFAULT_SPEED_MAX:int			= 15;
	static protected    const DEFAULT_TURN_RATE:Number		= 20;
	static protected    const DEFAULT_ACCEL_RATE:Number		= 0.5;

	public static const COLLISION_MARKER:String 			= "COLLISION_MARKER";
	public static const TRAIL_MARKER:String 				= "TRAIL_MARKER";

	// scratch objects to save on allocation of memory
	//private static const _sZERO_VEC:Vector3D 				= new Vector3D();
	protected static var _sScratchVector:Vector3D			= new Vector3D();
	protected static var _sScratchMatrix:Matrix3D			= new Matrix3D();
	
	protected var _ct:CollisionTest							= null;
	protected var _collisionCandidates:Vector.<VoxelModel> 	= null;
	protected var _displayCollisionMarkers:Boolean 			= false;
	protected var _leaveTrail:Boolean 						= false;
	protected var _forward:Boolean 							= false;
	protected var _inventoryBitmap:String					= "userInventory.png";

	protected var _maxFallRate:SecureNumber 				= new SecureNumber( DEFAULT_FALL_RATE );
	// This should be at the controllable model leve

	protected var 	_turnRate:Number 						= DEFAULT_TURN_RATE; // 2.5 for ship
	protected var 	_accelRate:Number 						= DEFAULT_ACCEL_RATE;
	private var 	_onSolidGround:Boolean;					// INSTANCE NOT EXPORTED

	public function get 	onSolidGround():Boolean 				{ return _onSolidGround; }
	public function set 	onSolidGround(val:Boolean):void 		{ _onSolidGround = val; }
	public function get		accelRate():Number 						{ return _accelRate; }

	private var 	_clipVelocityFactor:SecureNumber		= new SecureNumber(DEFAULT_CLIP_VELOCITY); 		// INSTANCE NOT EXPORTED
	public function get		clipVelocityFactor():Number 			{ return _clipVelocityFactor.val; }
	public function set		clipVelocityFactor($val:Number):void { _clipVelocityFactor.val = $val; }
	protected var _maxSpeed:SecureNumber 					= new SecureNumber( DEFAULT_SPEED_MAX );
	public function get 	maxSpeed():Number 						{ return _maxSpeed.val; }
	public function set 	maxSpeed($value:Number):void 			{ _maxSpeed.val = $value; }

	protected function get 	mMaxFallRate():Number 					{ return _maxFallRate.val; }
	protected function set 	mMaxFallRate($value:Number):void 		{ _maxFallRate.val = $value; }
	
	protected function get 	mForward():Boolean 						{ return _forward; }
	protected function set 	mForward($val:Boolean):void 			{ _forward = $val; }
	
	
	public function ControllableVoxelModel( ii:InstanceInfo ):void {
		super( ii );
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		Globals.g_app.addEventListener( ShipEvent.THROTTLE_CHANGED, throttleEvent, false, 0, true );
		ModelEvent.addListener( ModelEvent.CHILD_MODEL_ADDED, onChildAdded );
		CursorSizeEvent.addListener( CursorSizeEvent.SET, adjustSpeedMultiplier );
		_ct = new CollisionTest( this );
		collisionPointsAdd();
	}

/*	protected function adjustSpeedMultiplier( e:CursorSizeEvent ): void {
		if ( this == VoxelModel.controlledModel ) {
			Log.out("ControllableVoxelModel.adjustSpeedMultiplier - ONE");
			VoxelModel.controlledModel.instanceInfo.setSpeedMultipler(1);
		}
	}*/

	// This allows the player to move more slowly when adjusting small grains
	protected function adjustSpeedMultiplier( e:CursorSizeEvent ): void {
		if ( this == VoxelModel.controlledModel && EditCursor.isEditing ) {
			//Log.out( "Player.adjustSpeedMultiplier - size: " + e.size );
			VoxelModel.controlledModel.instanceInfo.setSpeedMultiplier( Math.max( e.size, 0.5 ) );
		} else {
			//Log.out( "Player.adjustSpeedMultiplier - is controlledModel? : " + (this == VoxelModel.controlledModel) + " isEditing: " + EditCursor.isEditing );
			VoxelModel.controlledModel.instanceInfo.setSpeedMultiplier( 1 );
		}
	}



	override protected function processClassJson():void {
		super.processClassJson();
		clipVelocityFactor = DEFAULT_CLIP_VELOCITY/100; // setting it to 0.95
		if ( modelInfo.dbo && modelInfo.dbo.controllableVoxelModel ) {
			var cmInfo:Object = modelInfo.dbo.controllableVoxelModel;
			
			if ( cmInfo.clipFactor )
				clipVelocityFactor = cmInfo.clipFactor/100;
				
			if ( cmInfo.maxSpeed )
				maxSpeed = cmInfo.maxSpeed;
		}
//		else
//			Log.out( "ControllableVoxelModel.processClassJson - no ControllableModelInfo info found", Log.WARN );
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.controllableVoxelModel = {};
		modelInfo.dbo.controllableVoxelModel.clipFactor = clipVelocityFactor * 100;
		modelInfo.dbo.controllableVoxelModel.maxSpeed = maxSpeed;
	}
	
	override public function set dead(val:Boolean):void {
		super.dead = val;
		
		if ( VoxelModel.controlledModel && VoxelModel.controlledModel == this )
			loseControl( VoxelModel.controlledModel );
			
		Globals.g_app.removeEventListener( ShipEvent.THROTTLE_CHANGED, throttleEvent );
		ModelEvent.removeListener( ModelEvent.CHILD_MODEL_ADDED, onChildAdded );
	}

	override public function release():void
	{
		super.release();
		
	}
	protected function collisionPointsAdd():void {
		// TO DO Should define this in meta data??? RSF or using extents?
		if ( 0 < _ct.hasPoints() )
			return;

		if ( modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount ) {
			var oxel:Oxel = modelInfo.oxelPersistence.oxel;
			var sizeOxel:Number = oxel.gc.size() / 2;
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, 0 ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, sizeOxel*2 ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 0, sizeOxel, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel*2, sizeOxel, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, 0, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel*2, sizeOxel ) ) );
		}
		else
			Log.out( "ControllableVoxelModel.collisionPointsAdd - modelInfo.oxelPersistence.oxel not found for guid: " + modelInfo.guid, Log.WARN );
		
	}

	// Just here for the descendants to override
	protected function onChildAdded( me:ModelEvent ):void { }
	
	protected function throttleEvent( event:ShipEvent ):void
	{
		if ( event.instanceGuid != instanceInfo.instanceGuid )
			return;
			
		//Log.out( "Ship.throttleEvent - val: " + event.value );
		
		var val:Number = -event.value;
		if ( -0.05 < val && val < 0.05 )
		{
			stopEngines();
		}
		else
		{
			startEngines( val );
		}
	}
	
	override public function collisionTest( $elapsedTimeMS:Number ):Boolean {
		
		//if ( this === VoxelModel.controlledModel )
		if ( instanceInfo.usesCollision )
		{
			// check to make sure the ship or object you were on was not destroyed or removed
			//if ( lastCollisionModel && lastCollisionModel.instanceInfo.dead )
				//lastCollisionModelReset();
			
			if ( false == controlledModelChecks( $elapsedTimeMS ) )
			{
				setAnimation();
				return false;
			}
			else
				setAnimation();
		}
		
		return true;
	}
	
	protected function setAnimation():void
	{
	}
	
	protected function handleMouseMovement( $elapsedTimeMS:int ):void {
		throw new Error( "ControllableVoxelModel.handleMouseMovement - NEEDS TO BE OVERRIDEN" );
	}
	
	//static var temp:int = 0;
	private var _timeSinceLastMessageTime:int;
	override public function update($context:Context3D, $elapsedTimeMS:int):void {
		
		//var cm:* = VoxelModel.controlledModel;
		//var tm:* = this;
		if ( this === VoxelModel.controlledModel )
			handleMouseMovement( $elapsedTimeMS );
		
		if (complete)
			updateVelocity($elapsedTimeMS, clipVelocityFactor );
			
		super.update($context, $elapsedTimeMS);
		
		if ( !instanceInfo.positionGet.nearEquals( instanceInfo.positionGet, 0.01 ) )
			instanceInfo.positionSet = instanceInfo.positionGet;
		//camera.scale = instanceInfo.scale;
		// track not copied intentionally
		// Y Axis ok, X is wrong
// I think this is not longer needed. RSF - 5.1.2017
//		camera.center.setTo( instanceInfo.center.x, instanceInfo.center.y, instanceInfo.center.z );
		//var ccenter:Vector3D = camera.current.position;
		//camera.center.setTo( instanceInfo.center.x + ccenter.x, instanceInfo.center.y + ccenter.y, instanceInfo.center.z + ccenter.z );
		
		if ( leaveTrail )
			leaveTrailMarkers();

        _timeSinceLastMessageTime += $elapsedTimeMS;
		if ( Globals.online && this == VoxelModel.controlledModel ) {
            if ( _timeSinceLastMessageTime > 60 ) {
                _timeSinceLastMessageTime = 0;
                //Log.out( "MovementMessage - dispatch movement message" );
                dispatchMovementEvent();
			}
		}


		//if ( 20 <= temp )
		//{
			//Log.out( "ControllableVoxelModel.update - ii position: " + instanceInfo.positionGet + "  cam position: " + camera.positionGet );
			//temp = 0;
		//}
		//temp++;
	}
	
	protected function collidedHandler( event:CollisionEvent ):void
	{
		if ( event.instanceGuid != this.instanceInfo.instanceGuid )
			return;
	
		if ( this == VoxelModel.controlledModel )
			return;
			
		//turn off collision, figure a safe route out, take it!
		escapeHandler();
	}
	
	protected function escapeHandler():void
	{
		Log.out( "ControllableVoxelModel.escapeHandler - GET THE HELL OUT OF HERE" );
	}
	
	override public function setTargetLocation( $loc:Location ):void 
	{
		/*
		 * This is all current broken - not sure what it does, but I think it transfers the motion of the collision model to the player
		if ( lastCollisionModel )
		{
			// Add into your position, the change due to the change in ships position
			// this takes into account gravity. I am really only trying to maintain the x,z here.
			// except for when I have a UP transform.
			loc.positionSet = lastCollisionModel.modelToWorld( positionGetOld );
			// if we dont use this, then we dont get benifit of gravity
			//worldSpaceTargetPosition.y = _worldSpacePosition.y;
			
			// Add into your rotation, the change due to the change in ships rotation
			var rotDiff:Vector3D = lastCollisionModel.instanceInfo.rotationGet.subtract( rotationGetOld );
			if ( false == _sZERO_VEC.nearEquals( rotDiff, 0.01 ) )
				rotationSet = rotationGet.subtract( rotDiff );
		}
		*/
		
		// clamp player mouse rotation
		if ( $loc.rotationGet.x >= 90 )
			$loc.rotationSet = new Vector3D( 89.99, $loc.rotationGet.y, $loc.rotationGet.z );
		else if ( $loc.rotationGet.x <= -90 )
			$loc.rotationSet = new Vector3D( -89.99, $loc.rotationGet.y, $loc.rotationGet.z );
		
		// If you are are on solid ground, you cant change the angle of the avatar( or controlled object ) 
		// other then turning right and left
		_sScratchMatrix.identity();
//		if ( !onSolidGround )
//			_sScratchMatrix.appendRotation( -$loc.rotationGet.x, Vector3D.X_AXIS );
		_sScratchMatrix.appendRotation( -$loc.rotationGet.y,   Vector3D.Y_AXIS );
		
		var dvMyVelocity:Vector3D = _sScratchMatrix.transformVector( $loc.velocityGet );
		if ( dvMyVelocity.length )
		{
			_sScratchVector.setTo( $loc.positionGet.x, $loc.positionGet.y, $loc.positionGet.z );
			_sScratchVector.decrementBy( dvMyVelocity );
			$loc.positionSet = _sScratchVector;
		}
		
		//Log.out( "ControllableVoxelModel.calculateTargetPosition - worldSpaceTargetPosition: " + worldSpaceTargetPosition );
	}
	
	public function fall( $loc:Location, $elapsedTimeMS:int ):void
	{
		//Log.out( "Fall PRE: " + $loc.velocityGet.y );
		if ( mMaxFallRate > $loc.velocityGet.y )
			$loc.velocitySetComp( $loc.velocityGet.x, $loc.velocityGet.y + (0.0033333333333333 * $elapsedTimeMS) + 0.5, $loc.velocityGet.z );
		//Log.out( "Fall PST: " + $loc.velocityGet.y );
	}

	public function jump( mutliplier:Number = 1 ):void
	{
		//Log.out( "Jump PRE: " + instanceInfo.velocityGet.y );
		instanceInfo.addNamedTransform( 0, -8 * mutliplier, 0, 100, ModelTransform.VELOCITY, "jump" );
		//Log.out( "Jump PST: " + instanceInfo.velocityGet.y );
	}

	private static var _s_scratchLocation:Location = new Location();
	protected function controlledModelChecks( $elapsedTimeMS:Number ):Boolean {
		// set our next position by adding in velocities
		// If there is no collision or gravity, this is where the model would end up.
		var loc:Location = _s_scratchLocation;
// TEMP - why TEMP RSF???
		loc.setTo( instanceInfo );
		setTargetLocation( loc );
		//Log.out( "CVM.controlledModelChecks - loc.positionSet: " + loc.positionGet );
		
		const STEP_UP_CHECK:Boolean = true;
		// does model have collision, if no collision, then why bother with gravity
		if ( instanceInfo.usesCollision ) {
			_collisionCandidates = ModelCacheUtils.whichModelsIsThisInfluencedBy( this );
			//trace( "collisionTest: " + _collisionCandidates.length )
			onSolidGround = false;
			if ( 0 == _collisionCandidates.length ) {
				if ( usesGravity )
					fall( loc, $elapsedTimeMS );

				// check the adjusted location to see if it is near the old location, if so, don't change it
				if ( !instanceInfo.nearEquals( loc ) )
					instanceInfo.setTo( loc );
			} else {
				var maxCollisionPointCount:int = -1;
				for each ( var collisionCandidate:VoxelModel in _collisionCandidates ) {
					// if it collided or failed to step up
					// restore the previous position
					var collisionPointCount:int = collisionCheckNew( $elapsedTimeMS, loc, collisionCandidate, STEP_UP_CHECK );
					maxCollisionPointCount = Math.max( maxCollisionPointCount, collisionPointCount );
				}

				if ( -1 < collisionPointCount ) {
					Globals.g_app.dispatchEvent( new CollisionEvent( CollisionEvent.COLLIDED, this.instanceInfo.instanceGuid ) );
					instanceInfo.restoreOld( collisionPointCount );
					instanceInfo.velocityReset();
					return false;
				}
				else {		// New position is valid
// TEMP - why TEMP RSF???
					if ( true == usesGravity && false == onSolidGround  )
						fall( loc, $elapsedTimeMS );

					instanceInfo.setTo(loc);
				}

			}
		}
		else {
// TEMP - why TEMP RSF???
			instanceInfo.setTo(loc);
		}
		
		return true;
	}

	protected function controlledModelChecksVerbose( $elapsedTimeMS:Number ):Boolean {
		// set our next position by adding in velocities
		// If there is no collision or gravity, this is where the model would end up.
		var loc:Location = _s_scratchLocation;
		loc.setTo( instanceInfo );
		setTargetLocation( loc );
		//Log.out( "CVM.controlledModelChecks - loc.positionSet: " + loc.positionGet );

		const STEP_UP_CHECK:Boolean = true;
		// does model have collision, if no collision, then why bother with gravity
		if ( instanceInfo.usesCollision )
		{
			var timer:int = getTimer();
			var test:GrainIntersection;
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.FRONT);
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.BACK);
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.LEFT);
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.RIGHT);
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.UP);
			//if ( test )
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );
			//else
			//Log.out("CVM.test - findClosestIntersectionInDirection NO MODEL: " );
			//test = Globals.g_modelManager.findClosestIntersectionInDirection(ModelManager.DOWN);
			//Log.out("CVM.test - findClosestIntersectionInDirection point: " + test.point );

//				Log.out("CVM.test - findClosestIntersectionInDirection took: " + (getTimer() - timer));


			_collisionCandidates = ModelCacheUtils.whichModelsIsThisInfluencedBy( this );
			//trace( "collisionTest: " + _collisionCandidates.length )
			if ( 0 == _collisionCandidates.length )
			{
				if ( usesGravity )
				{
					fall( loc, $elapsedTimeMS );
				}
				onSolidGround = false;
				instanceInfo.setTo( loc );
			}
			else
			{
				for each ( var collisionCandidate:VoxelModel in _collisionCandidates )
				{
					// if it collided or failed to step up
					// restore the previous position


					var collisionPointCount:int = collisionCheckNew( $elapsedTimeMS, loc, collisionCandidate, STEP_UP_CHECK );
					if ( -1 < collisionPointCount )
					{
						Globals.g_app.dispatchEvent( new CollisionEvent( CollisionEvent.COLLIDED, this.instanceInfo.instanceGuid ) );
						instanceInfo.restoreOld( collisionPointCount );
						instanceInfo.velocityReset();
						return false;
					}
					// New position is valid
					else
						instanceInfo.setTo( loc );
				}
			}
		}
		else
			instanceInfo.setTo( loc );

		return true;
	}

	override public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
		super.takeControl( $modelLosingControl, $addAsChild );
		if ( Network.userId != Network.LOCAL )
			InventoryInterfaceEvent.dispatch( new InventoryInterfaceEvent( InventoryInterfaceEvent.DISPLAY, instanceInfo.instanceGuid, inventoryBitmap ) );

		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, keyDown );
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_UP, keyUp );
	}
	
	override public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void {
		super.loseControl( $modelDetaching, $detachChild );
		// save inventory
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, instanceInfo.instanceGuid, null ) );
		// no longer controlling this model
		// shut down the toolbar
		InventoryInterfaceEvent.dispatch( new InventoryInterfaceEvent( InventoryInterfaceEvent.CLOSE, instanceInfo.instanceGuid, null ) );
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, keyDown );
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_UP, keyUp );
	}

	// This is for direct control of model, such as in the voxel bomber.
	protected function keyDown(e:KeyboardEvent):void {
		throttleEvent( new ShipEvent( ShipEvent.THROTTLE_CHANGED, instanceInfo.instanceGuid, -_accelRate ) );
	}

	// This is for direct control of model, such as in the voxel bomber.
	protected function keyUp(e:KeyboardEvent):void {
		throttleEvent( new ShipEvent( ShipEvent.THROTTLE_CHANGED, instanceInfo.instanceGuid, _accelRate ) );
	}


	/*
	 * Checks whether this $loc is valid, meaning none of the object's collision points
	 * are in a solid oxel. This is the most basic approach. The model just stops if it collides.
	 * $loc: 				Copy of the avatar's location object
	 * $collisionCandidate: The voxel model to collide with
	 * $stepUpCheck: 		True if the model should try to step up after colliding (Player Only)
	 * returns -1 if new position is valid, returns 0-2 if there was collision
	 * 0-2 is the number of steps back to take in position queue
	*/ 
	
	protected function collisionCheckNew( $elapsedTimeMS:Number, $loc:Location, $collisionCandidate:VoxelModel, $stepUpCheck:Boolean = false ):int {
		//Log.out( "ControllableVoxelModel.collisionCheckNew - ENTER" );
		// reset all the points to be in a non collided state
		if ( _ct.hasPoints() )
		{
			_ct.setValid();
			var points:Vector.<CollisionPoint> = _ct.collisionPoints();
			for each ( var cp:CollisionPoint in points )
			{
				// takes the CollisionPoint's point which is in model space, and puts it in world space
				var posWs:Vector3D = $loc.modelToWorld( cp.point );
				// pass in the world space coordinate to get back whether the oxel at the location is solid
				$collisionCandidate.isSolidAtWorldSpace( cp, posWs, MIN_COLLISION_GRAIN );
				// if collided, increment the count on that collision point set
				if ( true == cp.collided )
				{
					return 1;
				}
			}
		}
		// if no points or no collision, return -1 success!
		return -1;
	}
	
	protected function startEngines( val:Number, name:String = "" ):void
	{
	}
	
	protected function stopEngines():void
	{
	}
	
	private var  	count:int 			= 0;
	private function leaveTrailMarkers():void
	{
		if ( 0 == count % 20 ) {
			var trailMarker:InstanceInfo 	= new InstanceInfo();
			trailMarker.modelGuid			= ControllableVoxelModel.TRAIL_MARKER;
			trailMarker.positionSet 		= instanceInfo.positionGet;
            trailMarker.addTransform( 0, 0, 0, 2000, ModelTransform.LIFE );
			trailMarker.name				= ControllableVoxelModel.TRAIL_MARKER + count;
			new ModelMaker( trailMarker, true , false );
		}
		count++;
	}

	static public function trailMarkerCreate():void {
		var iiR:InstanceInfo = new InstanceInfo();
		iiR.modelGuid = ControllableVoxelModel.TRAIL_MARKER;
		new ModelMakerGenerate( iiR, GenerateCube.script( 0, TypeInfo.BLUE, true ), true, false );
	}

	
	public function get leaveTrail():Boolean { return _leaveTrail; }
	public function set leaveTrail(value:Boolean):void { _leaveTrail = value; }
	public function get collisionMarkers():Boolean { return _displayCollisionMarkers; }
	public function set collisionMarkers($value:Boolean):void {
		if ( $value )
			_ct.markersAdd();
		else
			_ct.markersRemove();

		_displayCollisionMarkers = $value;
	}
	
	public function get inventoryBitmap():String { return _inventoryBitmap; }
	public function set inventoryBitmap(value:String):void { _inventoryBitmap = value; }

	private static const ROTATE_FACTOR:Number = 0.06;
	override public function updateVelocity( $elapsedTimeMS:int, $clipFactor:Number ):Boolean
	{
		//Log.out( "updateVelocity this == VoxelModel.controlledModel " + (this == VoxelModel.controlledModel) + " Globals.active: " + Globals.active );

		var changed:Boolean = false;

		var cm:VoxelModel = VoxelModel.controlledModel;
		// if app is not active, we still need to clip velocitys, but we dont need keyboard or mouse movement
		if ( this == cm && Globals.active )
		{
			var vel:Vector3D = instanceInfo.velocityGet;
			var speedVal:Number = instanceInfo.speed( $elapsedTimeMS ) / 4;

			// Add in movement factors
			if ( MouseKeyboardHandler.forward )	{
				if ( instanceInfo.velocityGet.length < maxSpeed ) {
					if ( MouseKeyboardHandler.isShiftKeyDown )
						instanceInfo.velocitySetComp( vel.x, vel.y, vel.z + speedVal * 4 );
					else
						instanceInfo.velocitySetComp( vel.x, vel.y, vel.z + speedVal );
					changed = true;
					mForward = true;
				}
			}
			else {
				mForward = false;
			}

			if ( MouseKeyboardHandler.backward )	{ instanceInfo.velocitySetComp( vel.x, vel.y, vel.z - speedVal ); changed = true; }
//			if ( MouseKeyboardHandler.leftSlide )	{ instanceInfo.velocitySetComp( vel.x + speedVal, vel.y, vel.z ); changed = true; }
//			if ( MouseKeyboardHandler.rightSlide )	{ instanceInfo.velocitySetComp( vel.x - speedVal, vel.y, vel.z ); changed = true; }
			if ( MouseKeyboardHandler.leftSlide )	{
				const currentRotP:Vector3D = instanceInfo.rotationGet;
				instanceInfo.rotationSetComp( currentRotP.x, currentRotP.y - ROTATE_FACTOR * $elapsedTimeMS, currentRotP.z );
				const currentCamRotP:Vector3D = CameraLocation.rotation;
				CameraLocation.rotation.setTo( currentCamRotP.x, currentCamRotP.y - ROTATE_FACTOR * $elapsedTimeMS, 0 );
				changed = true;
			}
			if ( MouseKeyboardHandler.rightSlide ) {
				const currentRot:Vector3D = instanceInfo.rotationGet;
				instanceInfo.rotationSetComp(currentRot.x, currentRot.y + ROTATE_FACTOR * $elapsedTimeMS, currentRot.z);
				const currentCamRot:Vector3D = CameraLocation.rotation;
				CameraLocation.rotation.setTo( currentCamRot.x, currentCamRot.y + ROTATE_FACTOR * $elapsedTimeMS, 0 );
				changed = true;
			}
			if ( MouseKeyboardHandler.down )	  	{ instanceInfo.velocitySetComp( vel.x, vel.y + speedVal, vel.z ); changed = true; }
			if ( MouseKeyboardHandler.up )
			{
				if ( cm.usesGravity ) {
					// Idea here is to keep the player from jumping unless their feet are on the ground.
					// If you wanted to add rocket boots, this is where is what it would effect
					if ( onSolidGround ) {
						jump( 2 );
						changed = true;
					}
				}
				else  {
					instanceInfo.velocitySetComp( vel.x, vel.y - speedVal, vel.z );
					changed = true;
				}
			}
		}
		
		// clip factor can scale quickly when diving.
		// so if it increases the speed, make sure speed is not over max
		if ( $clipFactor < 1 )
			instanceInfo.velocityScaleBy( $clipFactor );
		else
		{
			if ( instanceInfo.velocityGet.length < maxSpeed ) 				
				instanceInfo.velocityScaleBy( $clipFactor );
		}
		
		instanceInfo.velocityClip();
		
		//trace( "InstanceInfo.updateVelocity: " + velocity );
		return changed;	
	}
}
}
