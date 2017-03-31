/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.renderer.lamps.BlackLamp;
import com.voxelengine.renderer.lamps.Lamp;
import com.voxelengine.renderer.lamps.LampBright;
import com.voxelengine.renderer.lamps.RainbowLight;
import com.voxelengine.renderer.lamps.ShaderLight;
import com.voxelengine.renderer.lamps.Torch;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.worldmodel.MouseKeyboardHandler;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.inventory.ObjectTool;
import com.voxelengine.worldmodel.models.CameraLocation;
import com.voxelengine.worldmodel.models.CollisionPoint;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.weapons.Bomb;
import com.voxelengine.worldmodel.weapons.Gun;

import flash.display3D.Context3D;

import flash.geom.Vector3D;
import flash.utils.getQualifiedClassName;

import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.server.Network

import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ControllableVoxelModel;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube


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

	public function Avatar( instanceInfo:InstanceInfo )
	{ 
		//Log.out( "Avatar CREATED" );
		super( instanceInfo );
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
	}

	static public function buildExportObject( obj:Object, model:* ):Object {
		ControllableVoxelModel.buildExportObject( obj, model );
		obj.avatar = {};
		//var thisModel:ControllableVoxelModel = model as ControllableVoxelModel;
		return obj;
	}
	

	override public function collisionTest( $elapsedTimeMS:Number ):Boolean {

//		if ( this === VoxelModel.controlledModel )
		{
			// check to make sure the ship or object you were on was not destroyed or removed
			//if ( lastCollisionModel && lastCollisionModel.instanceInfo.dead )
			//lastCollisionModelReset();

			if ( false == controlledModelChecks( $elapsedTimeMS ) )
			{
				stateSet( "PlayerAniStand", 1 ); // Should be crash?
				return false;
			}
			else
				setAnimation();
		}

		return true;
	}


	override protected function setAnimation():void	{

		/*if ( EditCursor.toolOrBlockEnabled )
		 {
		 stateSet( "Pick", 1 );
		 }*/

		if ( -0.4 > instanceInfo.velocityGet.y )
		{
			updateAnimations( "Jump", 1 );
		}
		else if ( 0.4 < instanceInfo.velocityGet.y )
		{
			updateAnimations( "Fall", 1 );
		}
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.z )  )
		{
			updateAnimations( "Walk", 2 );
		}
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.x )  )
		{
			updateAnimations( "Slide", 1 );
		}
		else
		{
			stateSet( "Stand", 1 );
		}
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
		// TO DO Should define this in meta data??? RSF or using extents?
		// diamond around feet
		if ( !_ct.hasPoints() ) {
			_ct.addCollisionPoint( new CollisionPoint( FALL, new Vector3D( 7.5, -1, 7.5 ), false ) );

			_ct.addCollisionPoint( new CollisionPoint( FOOT, new Vector3D( 7.5, Globals.AVATAR_HEIGHT_FOOT, 7.5 ), true ) );
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

		//_ct.markersAdd();
	}

	override protected function cameraAddLocations():void {
		//if ( Globals.isDebug )
		//	camera.addLocation( new CameraLocation( true, 0, 0, 0 ) );

//			camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT - 4, 0 ) );
//			camera.addLocation( new CameraLocation( true, 0, Globals.AVATAR_HEIGHT - 4, 0) );
		//camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT - 4, Globals.AVATAR_WIDTH/2) );
		camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT - 4, Globals.AVATAR_WIDTH/2 - 4) );
		camera.addLocation( new CameraLocation( false, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT - 4, 50) );
//			camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT + 20, 50) );
		camera.addLocation( new CameraLocation( false, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT, 100) );
//			camera.addLocation( new CameraLocation( true, Globals.AVATAR_WIDTH/2, Globals.AVATAR_HEIGHT, 250) );
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
			if ( VoxelModel.controlledModel == this )
				vmPos = instanceInfo.positionGet;
			else
				vmPos = VoxelModel.controlledModel.instanceInfo.positionGet;

			sl.position.setTo( vmPos.x + 4, vmPos.y + 30, vmPos.z );
			sl.update();
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
				&& false == MouseKeyboardHandler.ctrl
				&& true == MouseKeyboardHandler.active
				&& 0 == Globals.openWindowCount )
		{
			// up down
			var dx:Number = 0;
			dx = MouseKeyboardHandler.getMouseYChange() / MOUSE_LOOK_CHANGE_RATE;
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

}
}