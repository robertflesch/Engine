/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.oxel.Oxel;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ShipEvent;
import com.voxelengine.worldmodel.models.types.Engine;
import com.voxelengine.worldmodel.weapons.Gun;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.SoundCache;

/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class Ship extends ControllableVoxelModel
{
	private	var _up:Boolean = false;
	private	var _down:Boolean = false;
	private	var _right:Boolean = false;
	private	var _left:Boolean = false;
	private const SHIP_CLIP_FACTOR:Number = 0.98;
//		private const MAX_ROTATION_RATE:int = 1440;

	// says it is unused, but it is used dynamically by AnimationCache.requestAnimationClass
	static public function getAnimationClass():String { return null; }
	protected var _engines:Vector.<VoxelModel> = new Vector.<VoxelModel>;
	protected var _guns:Vector.<Gun> = new Vector.<Gun>;
	protected var _bombs:Vector.<VoxelModel> = new Vector.<VoxelModel>;


	public function Ship( ii:InstanceInfo )
	{
		super( ii );
	}

	override public function init( $mi:ModelInfo, $buildState:String = ModelMakerBase.MAKING ):void {
		super.init( $mi, $buildState );
		// TODO These should be loading from the json file
		clipVelocityFactor = SHIP_CLIP_FACTOR;
		//_turnRate = 20;
		//_accelRate = 50;

		Globals.g_app.addEventListener( ShipEvent.ALTITUDE_CHANGED, altitudeEvent, false, 0, true );
		Globals.g_app.addEventListener( ShipEvent.DIRECTION_CHANGED, directionEvent, false, 0, true );
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.ship = {};
	}

	override protected function processClassJson( $buildState:String ):void {
        super.processClassJson( $buildState );
		if ( modelInfo.dbo.ship ) {
			var info:Object = modelInfo.dbo.ship;
		}
		else
			Log.out( "Propeller.processClassJson - NO Propeller INFO FOUND - Setting to defaults", Log.WARN );
	}

	override protected function collisionPointsAdd():void {
		// TO DO Should define this in meta data??? RSF or using extents?

		if ( modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount ) {
			var oxel:Oxel = modelInfo.oxelPersistence.oxel;
			var sizeOxel:Number = oxel.gc.size() / 2;
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, 0 ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel, sizeOxel*2 ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( 0, sizeOxel, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel*2, sizeOxel, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, 0, sizeOxel ) ) );
			_ct.addCollisionPoint( new CollisionPoint( BODY, new Vector3D( sizeOxel, sizeOxel*2, sizeOxel ) ) );

			//_ct.addCollisionPointMarkers();
		}
		else
			Log.out( "Ship.collisionPointsAdd - modelInfo.oxelPersistence.oxel not found for guid: " + modelInfo.guid, Log.WARN );
	}

	private function altitudeEvent( event:ShipEvent ):void
	{
		if ( event.instanceGuid != instanceInfo.instanceGuid )
			return;

		Log.out( "Ship.altitudeEvent - val: " + event.value );

		var val:Number = event.value;
		var shipAccelerationRate:Number = 0.5;
		if ( -0.05 < val && val < 0.05 )
		{
			Log.out( "Ship.altitudeEvent - remove altitude transform" );
			instanceInfo.removeNamedTransform( ModelTransform.VELOCITY, SHIP_ALTITUDE );
		}
		else
		{
			var ms:Number = -shipAccelerationRate * val;
			Log.out( "Ship.altitudeEvent - adding altitude transform with value: " + ms );
			instanceInfo.addNamedTransform( 0, ms, 0, -1, ModelTransform.VELOCITY, SHIP_ALTITUDE );
		}
	}

	private function directionEvent( event:ShipEvent ):void
	{
		if ( event.instanceGuid != instanceInfo.instanceGuid )
			return;

		Log.out( "Ship.directionEvent - val: " + event.value );

		var val:Number = event.value;
		var turnRate:Number = -7.5;

		instanceInfo.addNamedTransform( 0, val * turnRate, 0, -1, ModelTransform.ROTATION, SHIP_ROTATION );
	}


	// rotation of 0.5 max, and -0.5 min
	override protected function startEngines( val:Number, name:String = "" ):void
	{
		if ( 0 == _engines.length )
		{
			Log.out( "Ship.startEngines - NO WORKING ENGINES" );
			return;
		}

		for each ( var engine:Engine in _engines )
		{
			if ( name != "" )
			{
				if ( engine.modelInfo.name == name )
					engine.start( val, this );

			}
			else
				engine.start( val, this );
		}
	}

	override protected function stopEngines():void
	{
		for each ( var engine:Engine in _engines )
			engine.stop( this );
	}

	// This is for direct control of model, such as in the voxel bomber.
	override protected function keyDown(e:KeyboardEvent):void {
		switch (e.keyCode) {
			case 87: case Keyboard.UP:
				if ( !_up )
				{
					throttleEvent( new ShipEvent( ShipEvent.THROTTLE_CHANGED, _instanceInfo.instanceGuid, _accelRate ) );
					_up = true;
				}
				break;
			case 83: case Keyboard.DOWN:
				if ( !_down )
				{
					throttleEvent( new ShipEvent( ShipEvent.THROTTLE_CHANGED, _instanceInfo.instanceGuid, -_accelRate ) );
					_down = true;
				}
				break;
			case 65: case Keyboard.LEFT:
				if ( !_left )
				{
					Log.out( "Ship.onKeyDown - adding LEFT transform" );
					//instanceInfo.addNamedTransform( 0, _turnRate, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, SHIP_ROTATION );
					startEngines( 0.5, "Left" );
					_left = true;
				}
				break;
			case 68: case Keyboard.RIGHT:
				if ( !_right )
				{
					Log.out( "Ship.onKeyDown - adding RIGHT transform" );
					//instanceInfo.addNamedTransform( 0, -_turnRate, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, SHIP_ROTATION );
					startEngines( 0.5, "Right" );
					_right = true;
				}
				break;
		}

	//	Log.out( "Ship.onKeyDown" );
	}

	override protected function keyUp(e:KeyboardEvent):void {
		switch (e.keyCode) {
			case 87: case Keyboard.UP:
			case 83: case Keyboard.DOWN:
				if ( _up || _down )
				{
					instanceInfo.addNamedTransform( 0.001, 0, 0.001, 0.1, ModelTransform.VELOCITY, SHIP_VELOCITY );
					stopEngines();
					_up = _down = false;
				}
				 break;
			case 65: case Keyboard.LEFT:
			case 68: case Keyboard.RIGHT:
				if ( _left || _right )
				{
					instanceInfo.addNamedTransform( 0, 0, 0, 0.1, ModelTransform.ROTATION, SHIP_VELOCITY );
					stopEngines();
					_left = _right = false;
				}
				break;
		}
//			Log.out( "Ship.onKeyUp" );
	}



}
}
