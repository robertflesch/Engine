﻿/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{

import flash.display3D.Context3D;

import flash.geom.Vector3D;
import flash.utils.getQualifiedClassName;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.renderer.lamps.ShaderLight;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.worldmodel.MouseKeyboardHandler;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.CameraLocation;
import com.voxelengine.worldmodel.models.CollisionPoint;
import com.voxelengine.worldmodel.models.Location;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.OxelBad;
import com.voxelengine.worldmodel.weapons.Bomb;
import com.voxelengine.worldmodel.weapons.Gun;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;


public class Avatar extends ControllableVoxelModel
{
	//static private const 	HIPWIDTH:Number 			= (Globals.UNITS_PER_METER * 3)/8;
	static private const 	FALL:String					= "FALL";
	static private const 	FOOT:String					= "FOOT";
	static private const 	HEAD:String					= "HEAD";
//		static private const 	MOUSE_LOOK_CHANGE_RATE:int 	= 10000;
	static private const 	MOUSE_LOOK_CHANGE_RATE:int 	= 5000;
	static private const 	MIN_TURN_AMOUNT:Number 		= 0.09;
	static private const 	AVATAR_CLIP_FACTOR:Number 	= 0.90;
	static private var  	STEP_UP_MAX:int 			= 16;

	static public const MODEL_BIPEDAL_10:String = "MODEL_BIPEDAL_10";
    static public function getAnimationClass():String { return MODEL_BIPEDAL_10; }
    static public const MODEL_BIPEDAL_10_HEAD       :String = "Head";
    static public const MODEL_BIPEDAL_10_TORSO      :String = "Torso";
    static public const MODEL_BIPEDAL_10_ARMLEFT    :String = "ArmLeft";
    static public const MODEL_BIPEDAL_10_ARMRIGHT   :String = "ArmRight";
    static public const MODEL_BIPEDAL_10_HANDLEFT   :String = "HandLeft";
    static public const MODEL_BIPEDAL_10_HANDRIGHT  :String = "HandRight";
    static public const MODEL_BIPEDAL_10_THIGHLEFT  :String = "ThighLeft";
    static public const MODEL_BIPEDAL_10_THIGHRIGHT :String = "ThighRight";
    static public const MODEL_BIPEDAL_10_FOOTLEFT   :String = "FootLeft";
    static public const MODEL_BIPEDAL_10_FOOTRIGHT  :String = "FootRight";

    static public const MODEL_BIPEDAL_10_STAND      :String = "Stand";
	static public const MODEL_BIPEDAL_10_JUMP       :String = "Jump";
	static public const MODEL_BIPEDAL_10_FALL       :String = "Fall";
	static public const MODEL_BIPEDAL_10_WALK       :String = "Walk";
	static public const MODEL_BIPEDAL_10_SLIDE      :String = "Slide";
	static public const MODEL_BIPEDAL_10_RIDE       :String = "Ride";

    public function Avatar( instanceInfo:InstanceInfo ) {
		//Log.out( "Avatar CREATED" );
		super( instanceInfo );
		collectAttachments();
		collectStates();
	}

    static private var _attachmentsInitialized:Boolean;
    static private var _attachments:Vector.<String> = new Vector.<String>();
    static private function collectAttachments():void {
        if ( !_attachmentsInitialized ) {
            _attachmentsInitialized = true;
            _attachments.push(MODEL_BIPEDAL_10_HEAD);
            _attachments.push(MODEL_BIPEDAL_10_TORSO);
            _attachments.push(MODEL_BIPEDAL_10_ARMLEFT);
            _attachments.push(MODEL_BIPEDAL_10_ARMRIGHT);
            _attachments.push(MODEL_BIPEDAL_10_HANDLEFT);
            _attachments.push(MODEL_BIPEDAL_10_HANDRIGHT);
            _attachments.push(MODEL_BIPEDAL_10_THIGHLEFT);
            _attachments.push(MODEL_BIPEDAL_10_THIGHRIGHT);
            _attachments.push(MODEL_BIPEDAL_10_FOOTLEFT);
            _attachments.push(MODEL_BIPEDAL_10_FOOTRIGHT);
        }
    }

	static private var _statesInitialized:Boolean;
	static private var _states:Vector.<String> = new Vector.<String>();
	static private function collectStates():void {
		if ( !_statesInitialized ) {
			_statesInitialized = true;
			_states.push(MODEL_BIPEDAL_10_STAND);
			_states.push(MODEL_BIPEDAL_10_JUMP);
			_states.push(MODEL_BIPEDAL_10_FALL);
			_states.push(MODEL_BIPEDAL_10_WALK);
			_states.push(MODEL_BIPEDAL_10_SLIDE);
			_states.push(MODEL_BIPEDAL_10_RIDE);
		}
	}

	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		// should just do this for the players avatar
		hasInventory = true;
		instanceInfo.usesCollision = true;
		clipVelocityFactor = AVATAR_CLIP_FACTOR;
		torchToggle();
		collisionMarkers = true;
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.avatar = {};
		//var thisModel:ControllableVoxelModel = $vm as ControllableVoxelModel;
	}
	
	override public function collisionTest( $elapsedTimeMS:Number ):Boolean {

//		if ( this === VoxelModel.controlledModel )
		{
			// check to make sure the ship or object you were on was not destroyed or removed
			//if ( lastCollisionModel && lastCollisionModel.instanceInfo.dead )
			//lastCollisionModelReset();

			if ( false == controlledModelChecks( $elapsedTimeMS ) ) {
				stateSet( MODEL_BIPEDAL_10_STAND, 1 ); // Should be crash?
				return false;
			}
			else
				setAnimation();
		}

		return true;
	}

	override protected function setAnimation():void	{
		//MODEL_BIPEDAL_10_RIDE
		/*if ( EditCursor.toolOrBlockEnabled )
		 {
		 stateSet( "Pick", 1 );
		 }*/
		if ( -0.4 > instanceInfo.velocityGet.y )
			updateAnimations( MODEL_BIPEDAL_10_JUMP, 1 );
		else if ( 0.4 < instanceInfo.velocityGet.y )
			updateAnimations( MODEL_BIPEDAL_10_FALL, 1 );
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.z )  )
			updateAnimations( MODEL_BIPEDAL_10_WALK, 2 );
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.x )  )
			updateAnimations( MODEL_BIPEDAL_10_SLIDE, 1 );
		else
			stateSet( MODEL_BIPEDAL_10_STAND, 1 );
		//trace( "Avatar.update - end" );
	}

	override protected function onChildAdded( me:ModelEvent ):void	{
		if ( me.parentInstanceGuid != instanceInfo.instanceGuid )
			return;

		var vm:VoxelModel = modelInfo.childModelFind( me.instanceGuid );
		if ( !vm ) {
			Log.out( "Avatar.onChildAdded ERROR FIND CHILD MODEL: " + me.instanceGuid );
		}
		//var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( me.instanceGuid );
//Log.out( "Avatar.onChildAdded model: " + vm.toString() );
		if ( vm is Engine )
			Log.out( "Avatar.onChildAdded - Player has ENGINE" );
		//_engines.push( vm );
		if ( vm is Gun )
			Log.out( "Avatar.onChildAdded - Player has GUN" );
		//_guns.push( vm );
		if ( vm is Bomb )
			Log.out( "Avatar.onChildAdded - Player has BOMP" );
		//_bombs.push( vm );
	}

	override protected function collisionPointsAdd():void {
		// TO DO Should define this in meta data??? RSF or using extents?
		// diamond around feet
		if ( !_ct.hasPoints() ) {
			_ct.addCollisionPoint( new CollisionPoint( FALL, new Vector3D( 7.5, -1, 7.5 ), false ) );
			_ct.addCollisionPoint( new CollisionPoint( "CENTER", new Vector3D( 7.5, 0, 7.5 ), false ) );
			 _ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 4, Globals.AVATAR_HEIGHT_FOOT, 7.5 ), true ) );
			 _ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 11, Globals.AVATAR_HEIGHT_FOOT, 7.5 ), true ) );
			 //_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_FOOT + STEP_UP_MAX/2, 0 ) ) );
			 //_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_FOOT + STEP_UP_MAX, 0 ) ) );
			 //			_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 11, Globals.AVATAR_HEIGHT_FOOT, 7.5 ) ) );
			 //			_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_FOOT, 11 ) ) );
			 //			_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 4, Globals.AVATAR_HEIGHT_FOOT, 7.5 ) ) );
			 // middle of chest
			 _ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_CHEST - 4, 7.5 ) ) );
			 _ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_CHEST, 7.5 ) ) );
			 _ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_CHEST + 4, 7.5 ) ) );
			 // diamond around feet
			 _ct.addCollisionPoint( new CollisionPoint( HEAD, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_HEAD, 7.5 ) ) );
			 _ct.addCollisionPoint( new CollisionPoint( HEAD, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_HEAD, 7.5 ), false ) );
			 //_ct.addCollisionPoint( new CollisionPoint( HEAD, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_HEAD, 15 ) ) );
			 //_ct.addCollisionPoint( new CollisionPoint( HEAD, new Vector3D( 0, Globals.AVATAR_HEIGHT_HEAD, 7.5 ) ) );
		}

		/*  0,0xxxxxx8xxxxxx15,0
		 *  x                x
		 *  x                x
		 *  x                x
		 *  0,4              x
		 * ...               ...
		 *  x                x
		 *  0,15xxxxx8xxxxxx15,15
		 *
		 * */
	}

	// returns -1 if new position is valid, returns 0-2 if there was collision
	// 0-2 is the number of steps back to take in position queue
	override protected function collisionCheckNew( $elapsedTimeMS:Number, $loc:Location, $collisionCandidate:VoxelModel, $stepUpCheck:Boolean = true ):int {

		//if ( $loc.velocityGet.y != 0 )
		//	Log.out( "Player.collisionCheckNew - ENTER: vel.y: " + instanceInfo.velocityGet.y );
		var foot:int = 0;
		var body:int = 0;
		var head:int = 0;
		var fall:int = 0;
		// reset all the points to be in a non collided state
		_ct.setValid();
		var points:Vector.<CollisionPoint> = _ct.collisionPoints();
		// the amount that the test point pushes forward from current position
		// currently basing it on velocity in Z dir
		const LOOK_AHEAD:int = 10;
		var velocityScale:Number = $loc.velocityGet.z * LOOK_AHEAD;

		for each ( var cp:CollisionPoint in points )
		{
			if ( cp.scaled )
				cp.scale( velocityScale );

			// takes the cp point which is in model space, and puts it in world space
			var posWs:Vector3D = $loc.modelToWorld( cp.pointScaled );

			// pass in the world space coordinate to get back whether the oxel at the location is solid
			$collisionCandidate.isSolidAtWorldSpace( cp, posWs, MIN_COLLISION_GRAIN, this );
			// if collided, increment the count on that collision point set
			if ( true == cp.collided )
			{
				if ( FALL == cp.name ) fall++;
				else if ( FOOT == cp.name ) foot++;
				else if ( BODY == cp.name ) body++;
				else if ( HEAD == cp.name ) head++;
			}
		}
		// fall point is in space! falling....
		if ( !fall )
		{
			//Log.out( "Player.collisionCheckNew - fall" );
			//Log.out( "Player.collisionCheckNew - FALL fall = 0, foot=0, stepUp: " + $stepUpCheck + " velocityGet.y: " + $loc.velocityGet.y );
			if ( usesGravity ) {
				this.fall( $loc, $elapsedTimeMS );
			}

			onSolidGround = false;
			if ( foot || body || head )
			{
				if ( mMaxFallRate > $loc.velocityGet.y && usesGravity )
					$loc.velocitySetComp( 0, $loc.velocityGet.y + (0.0033333333333333 * $elapsedTimeMS) + 0.5, 0 );

				return -1;
			}
			return -1;
		}

		// Everything is clear
		if ( !head && !foot && !body )
		{
			//Log.out( "Player.collisionCheckNew - all good" );
			return -1;
		}
		else if ( foot && !body && !head )
		{
			//Log.out( "Player.collisionCheckNew - foot" );
			lastCollisionModel = $collisionCandidate;
			onSolidGround = true;
			$loc.velocityResetY();

			// oxel that fall point is in
			var go:Oxel = points[0].oxel;
			// its location in MS (ModelSpace)
			var msCoord:int = go.getModelY();
			// add its height in MS
			msCoord += go.size_in_world_coordinates();
			// if foot oxel, then there are two choices
			// 1) foot is in ground, in which case we should adjust avatars position
			// 2) there is a step up chance

			// oxel that foot point is in
			var fo:Oxel = points[1].oxel;
			if ( OxelBad.INVALID_OXEL == fo )
					return -1;
			var msCoordFoot:int = fo.getModelY();
			msCoordFoot += fo.size_in_world_coordinates();
			// we need to do minor adjustment on foot position?
			if ( fo.gc.grain == go.gc.grain && fo.gc.grainY == go.gc.grainY || msCoord == msCoordFoot )
			{
				//Log.out( "Player.collisionCheckNew - FOOT in solid ground adjusting foot height" );
				// add its height in MS
				msCoord = msCoordFoot;
				_sScratchVector.setTo( 0, msCoord, 0 );
				var wsCoord:Vector3D = $collisionCandidate.modelToWorld( _sScratchVector );
				$loc.positionSetComp( $loc.positionGet.x, wsCoord.y, $loc.positionGet.z );
				//Log.out( "Player.collisionCheckNew - FOOT in solid ground adjusting foot height to: " + wsCoord.y );
				return -1;
			}
			else // step up chance
			{
				var stepUpSize:int = msCoordFoot - msCoord;
				if ( 0 == stepUpSize )
				{
					Log.out( "Player.collisionCheckNew - REJECT - step up size is 0 why? " + stepUpSize );
					return 0;
				}
				else if ( STEP_UP_MAX < stepUpSize )
				{
					Log.out( "Player.collisionCheckNew - REJECT - step TOO large: " + stepUpSize );
					return 0;
				}

				const STEP_SIZE_GRAIN:int = 4;
				if ( STEP_SIZE_GRAIN == fo.gc.grain )
				{
					var stepUpOxel:Oxel = fo.neighbor(Globals.POSY);
					if ( stepUpOxel.childrenHas() )
					{
						Log.out( "Player.collisionCheckNew - REJECT - step has kids or is solid: " + stepUpSize + " need a more detailed examination of children" );
						return 0;
					}
				}
				else if ( STEP_SIZE_GRAIN > fo.gc.grain ) // This grain is too small, bump up to STEP_SIZE
				{
					Log.out( "Player.collisionCheckNew - step smaller then l meter:" );
					var stepUpOxel1:Oxel = fo.neighbor(Globals.POSY);
					if ( OxelBad.INVALID_OXEL != stepUpOxel1 )
					{
						var msCoordFoot1:int = stepUpOxel1.getModelY();
						msCoordFoot1 += stepUpOxel1.size_in_world_coordinates();
						_sScratchVector.setTo( 0, msCoordFoot1, 0 );
						var wsCoord1:Vector3D = $collisionCandidate.modelToWorld( _sScratchVector );
						$loc.positionSetComp( $loc.positionGet.x, wsCoord1.y, $loc.positionGet.z );
						Log.out( "Player.collisionCheckNew - step  too small: adjusting foot height to: " + wsCoord1.y );
						return -1;
//						Log.out( "Player.collisionCheckNew - REJECT - step  too small: " + fo.gc.grain + " need a more detailed examination of children" );
//						return 0;
					}
				}
				//Log.out( "Player.collisionCheckNew - PASS stepupSize: " + stepUpSize + " ADDING transform" );

				// Dont like adding this to instance info... when everything else is using loc
				jump( 1 );
			}
		}
		else if ( ( head || body ) && !foot )
		{
			// We probably jumped up into something
			//Log.out( "Player.collisionCheckNew - HEAD failed to clear" );
			return 2;
		}
		else if ( head && body && foot )
		{
			// Wall crawling
			//Log.out( "Player.collisionCheckNew - EVERYTHING failed to clear" );
			return 0;
		}
		else if ( head || body || foot )
		{
			Log.out( "Player.collisionCheckNew - something failed to clear foot:" + foot + " body: " + body + " head: " + head );
			return 1;
		}
		Log.out( "Player.collisionCheckNew - ALL CLEAR" );
		return -1;
	}

	override protected function cameraAddLocations():void {
		//camera.addLocation( new CameraLocation( true, 0, 0, 0 ) );
		camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT, Globals.AVATAR_WIDTH/2 - 4) );
		camera.addLocation( new CameraLocation( false, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT, 50) );
		camera.addLocation( new CameraLocation( false, -Globals.AVATAR_WIDTH, Globals.AVATAR_HEIGHT, 50) );
		camera.addLocation( new CameraLocation( false, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT * 2, 50) );
		camera.addLocation( new CameraLocation( false, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT, 100) );
	}

	override public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
		Log.out( "Avatar.takeControl --------------------------------------------------------------------------------------------------------------------", Log.DEBUG );
		super.takeControl( $modelLosingControl, false );
		instanceInfo.usesCollision = true;
		// We need to grab the rotation of the old parent, otherwise we get rotated back to 0 since last rotation is 0
		if ( $modelLosingControl )
			instanceInfo.rotationSet = $modelLosingControl.instanceInfo.rotationGet;

		//GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_SHOW));
		var className:String = getQualifiedClassName( topmostControllingModel() );
		ModelEvent.dispatch( new ModelEvent( ModelEvent.TAKE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );

		torchToggle();
	}

	override public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void {
		Log.out( "Avatar.loseControl --------------------------------------------------------------------------------------------------------------------", Log.DEBUG );
		super.loseControl( $modelDetaching, false );
		instanceInfo.usesCollision = false;
	}

	override public function update($context:Context3D, $elapsedTimeMS:int):void	{

		if ( 0 < Shader.lightCount() ) {
			var sl:ShaderLight = Shader.lights(0);
			var vmPos:Vector3D;
			var cm:VoxelModel = VoxelModel.controlledModel;
			if ( cm ) {
				vmPos = cm.instanceInfo.positionGet;
				sl.position.setTo(vmPos.x + 4, vmPos.y + 30, vmPos.z);
				sl.update();
			}
		}

		super.update( $context, $elapsedTimeMS );
	}

	override protected function handleMouseMovement( $elapsedTimeMS:int ):void {
//		Log.out( "Avatar.handleMouseMovement - Globals.active: " + Globals.active
//				+ "  MouseKeyboardHandler.ctrl: " + MouseKeyboardHandler.ctrl
//				+ " MouseKeyboardHandler.active: " + MouseKeyboardHandler.active
//				+ " Globals.openWindowCount: " + Globals.openWindowCount  );
		if ( Globals.active
				//&& 0 == Globals.openWindowCount // this allows it to be handled in the getMouseYChange
				&& false == MouseKeyboardHandler.isCtrlKeyDown
				&& true == MouseKeyboardHandler.active
				&& 0 == Globals.openWindowCount )
		{
			// up down
			var dx:Number = MouseKeyboardHandler.getMouseYChange() / MOUSE_LOOK_CHANGE_RATE;
			dx *= $elapsedTimeMS;
			if ( MIN_TURN_AMOUNT >= Math.abs(dx) )
				dx = 0;

			// right left
			var dy:Number = MouseKeyboardHandler.getMouseXChange() / MOUSE_LOOK_CHANGE_RATE;
			dy *= $elapsedTimeMS;

			//Log.out( "Avatar.handleMouseMovement dy: " + dy + "   $elapsedTimeMS: " + $elapsedTimeMS )
			if ( MIN_TURN_AMOUNT >= Math.abs(dy) )
				dy = 0;
			//
			//Log.out( "Avatar.handleMouseMovement - rotation: " + instanceInfo.rotationGet );
			// I only want to rotate the head here, not the whole body. in the X dir.
			// so if I made the head the main body part, could I keep the rest of the head fixed on the x and z axis...
			instanceInfo.rotationSetComp( instanceInfo.rotationGet.x, instanceInfo.rotationGet.y + dy, instanceInfo.rotationGet.z );
			//camera.rotationSetComp( instanceInfo.rotationGet.x, instanceInfo.rotationGet.y, instanceInfo.rotationGet.z );
			// this uses the camera y rotation, but it breaks other things like where to dig.
			camera.rotationSetComp( camera.rotationGet.x + dx, instanceInfo.rotationGet.y, instanceInfo.rotationGet.z );
			//trace( "handleMouseMovement instanceInfo.rotationGet: " + instanceInfo.rotationGet + "  camera.rotation: " + camera.rotationGet );
		}
	}

	public function applyRegionInfoToPlayer():void {
		Log.out( "Region.applyRegionInfoToPlayer - DISABLED", Log.WARN );
		var playerPosition:Object = Region.currentRegion.playerPosition;
		if ( Region.currentRegion.playerPosition ) {
			//Log.out( "Player.onLoadingPlayerComplete - setting position to  - x: "  + playerPosition.x + "   y: " + playerPosition.y + "   z: " + playerPosition.z );
			instanceInfo.positionSetComp( playerPosition.x, playerPosition.y, playerPosition.z );
		}
		else
			instanceInfo.positionSetComp( 0, 0, 0 );

		var playerRotation:Object = Region.currentRegion.playerPosition;
		if ( playerRotation ) {
			//Log.out( "Player.onLoadingPlayerComplete - setting player rotation to  -  y: " + playerRotation );
			instanceInfo.rotationSet = new Vector3D( 0, playerRotation.y, 0 );
		}
		else
			instanceInfo.rotationSet = new Vector3D( 0, 0, 0 );

		usesGravity = Region.currentRegion.gravity;
	}


}
}