/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.oxel.Oxel;
import flash.geom.Vector3D;
import flash.utils.getQualifiedClassName;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.worldmodel.MouseKeyboardHandler;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.CameraLocation;
import com.voxelengine.worldmodel.models.CollisionPoint;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class Dragon extends Beast 
{
	public function Dragon( ii:InstanceInfo ) { 
		super( ii );
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		
		// TODO reimplement in handler
		//MouseKeyboardHandler.backwardEnabled = false;
		
		instanceInfo.usesCollision = true;
		hasInventory = true;
		//usesGravity = true;
		collisionMarkers = true;
		InventorySlotEvent.addListener( InventorySlotEvent.DEFAULT_REQUEST, defaultSlotDataRequest );
//		InventorySlotEvent.addListener( InventorySlotEvent.DEFAULT_RESPONSE, defaultSlotDataResponse );
		FunctionRegistry.functionAdd( loseControlHandler, "loseControlHandler" );
	}

	static public function buildExportObject( obj:Object ):Object {
		Beast.buildExportObject( obj )
		obj.dragon = new Object();
		return obj;
	}
	
	override protected function processClassJson():void {
		super.processClassJson();
		// no unique items at this level
		if ( modelInfo.dbo && modelInfo.dbo.dragon )
			var dragonInfo:Object = modelInfo.dbo.dragon;
		else
			Log.out( "Dragon.processClassJson - Dragon section not found: " + JSON.stringify( modelInfo.dbo ), Log.ERROR );
	}
/*		
	override protected function addClassJson():String {
		var jsonString:String = super.addClassJson();
		jsonString += ",";
		jsonString += "\"dragon\": { }";
		return jsonString;
	}
*/	
	
	override protected function collisionPointsAdd():void {
		// TO DO Should define this in meta oxelPersistance??? RSF or using extents?
		
		if ( modelInfo.oxelPersistance && modelInfo.oxelPersistance.oxel ) {
			var oxel:Oxel = modelInfo.oxelPersistance.oxel;
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
		else
			Log.out( "Dragon.collisionPointsAdd - modelInfo.oxelPersistance.oxel not found for guid: " + modelInfo.guid, Log.WARN );
	}

	override protected function cameraAddLocations():void {
		camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 20, 0) );
		camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 20, 50) );
		camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT + 30, 80) );
		//camera.addLocation( new CameraLocation( true, 16, Globals.AVATAR_HEIGHT - 40, 50) );
		camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT, 100) );
		camera.addLocation( new CameraLocation( false, 16, Globals.AVATAR_HEIGHT, 250) );
	}

	override public function stateSet($state:String, $lockTime:Number = 1):void {
		super.stateSet( $state, $lockTime );
		if ( anim ){
			speedMultiplier = anim.speedMultiplier;
			clipVelocityFactor = anim.clipVelocity;
		}
	}

	override protected function setAnimation():void	{
		
		if ( _stateLock )
			return;
		if ( !modelInfo.animationsLoaded )
			return;

		var climbFactor:Number = ( maxClimbAngle + instanceInfo.rotationGet.x) / maxClimbAngle;
		
		if ( onSolidGround ) {
			updateAnimations( "Walk", 0.5 );
			instanceInfo.velocityReset();
			stateLock( true, 500 );
		} else if ( stallSpeed > instanceInfo.velocityGet.z ) {
			updateAnimations( "Land", 0.5 );
		} else if ( -5 > instanceInfo.rotationGet.x ) {
			updateAnimations( "Fly", 1 - climbFactor );
		} else if ( 15 < instanceInfo.rotationGet.x ) {
			stateSet( "Dive" );
		} else { 		// Be fun to make this have the avatar put their arms out to the side
			if ( mForward )
				updateAnimations( "Fly", 0.5 );
			else
				stateSet( "Glide" );
		}
	}

	override public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
		VoxelModel.controlledModel.loseControl( null );
		//Log.out( "Dragon.takeControl --------------------------------------------------------------------------------------------------------------------", Log.WARN );
		//Log.out( "Dragon.takeControl - starting position: " + $vm.instanceInfo.positionGet );
		super.takeControl( $modelLosingControl, $addAsChild );
		$modelLosingControl.stateSet( "Ride");
		$modelLosingControl.stateLock( true );
		var className:String = getQualifiedClassName( topmostControllingModel() );
		ModelEvent.dispatch( new ModelEvent( ModelEvent.TAKE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.REQUEST, instanceInfo.instanceGuid, null ) );
	}

	override public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void {
		Log.out( "Dragon.loseControl --------------------------------------------------------------------------------------------------------------------", Log.WARN );
		super.loseControl( $modelDetaching, $detachChild );
		$modelDetaching.stateLock( false );
	}

	override public function updateVelocity( $elapsedTimeMS:int, $clipFactor:Number ):Boolean
	{
		var changed:Boolean = false;
		
		// if app is not active, we still need to clip velocitys, but we dont need keyboard or mouse movement
		if ( this == VoxelModel.controlledModel && Globals.active )
		{
			var vel:Vector3D = instanceInfo.velocityGet;
			var speedVal:Number = instanceInfo.speed( $elapsedTimeMS )/1000;
//			Log.out( "Dragon.updateVelocity - speed value calculated: " + speedVal + " is being set to 0.5" );

			speedVal = 0.5;

			// Add in movement factors
			if ( MouseKeyboardHandler.forward )	{ 
				if ( instanceInfo.velocityGet.length < maxSpeed ) {
					instanceInfo.velocitySetComp( 0, 0, vel.z + speedVal ); 
					changed = true; 
					mForward = true; }
			}
			else	
				{ mForward = false; }
			if ( MouseKeyboardHandler.backward )	{ instanceInfo.velocitySetComp( vel.x, vel.y, vel.z - speedVal ); changed = true; }
			if ( onSolidGround )
			{
				// Only allow slide left and right when on ground
				if ( MouseKeyboardHandler.leftSlide )	{ instanceInfo.velocitySetComp( vel.x + speedVal, vel.y, vel.z ); changed = true; }
				if ( MouseKeyboardHandler.rightSlide )	{ instanceInfo.velocitySetComp( vel.x - speedVal, vel.y, vel.z ); changed = true; }
			}
			else
			{
				if ( MouseKeyboardHandler.down )	  	{ instanceInfo.velocitySetComp( vel.x, vel.y + speedVal, vel.z ); changed = true; }
			}
			if ( MouseKeyboardHandler.up )          { instanceInfo.velocitySetComp( vel.x, vel.y - speedVal, vel.z ); changed = true; }
		}
		
		/*
		if ( !onSolidGround && instanceInfo.usesCollision && this == VoxelModel.controlledModel )
		{
			if ( mStallSpeed > instanceInfo.velocityGet.z && instanceInfo.velocityGet.length < mMaxSpeed  )
			{
				//Log.out( "Dragon.updateVelocity - stalled: " + instanceInfo. velocityGet.y + "  time: " + $elapsedTimeMS + "  tval: " + 0.0033333333333333 * $elapsedTimeMS );
				if ( mMaxFallRate > instanceInfo.velocityGet.y )
					instanceInfo.velocitySetComp( instanceInfo.velocityGet.x, instanceInfo.velocityGet.y + (0.001 * $elapsedTimeMS), instanceInfo.velocityGet.z );
			}
		}
		*/
		
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
	
	private function defaultSlotDataRequest( $ise:InventorySlotEvent ):void {
		if ( instanceInfo.instanceGuid == $ise.instanceGuid ) {
			Log.out( "Dragon.getDefaultSlotData - Loading default data into slots" , Log.WARN );
			
			var oa:ObjectAction = new ObjectAction( null, "loseControlHandler", "dismount.png", "Dismount" );
			InventorySlotEvent.create( InventorySlotEvent.SLOT_CHANGE, instanceInfo.instanceGuid, instanceInfo.instanceGuid, 0, oa );
			
			for each ( var gun:Gun in _guns )
				InventorySlotEvent.create( InventorySlotEvent.DEFAULT_REQUEST, instanceInfo.instanceGuid, gun.instanceInfo.instanceGuid, 0, null );
		}
	}
	/*
	private function defaultSlotDataResponse( $ise:InventorySlotEvent ):void {
		//if (  $ise.ownerGuid is child
	}

	private function ammoLoadComplete( $e:GunEvent ):void {
		var gun:Gun = _guns[0];
		var armory:Armory = gun.armory;
		var ammos:Vector.<Ammo> = armory.getAmmoList();
		for ( var i:int; i < ammos.length; i++ ) {
			//public function InventorySlotEvent( $type:String, $ownerGuid:String, $slotId:int, $item:ObjectInfo, $bubbles:Boolean = true, $cancellable:Boolean = false )
			InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE
			                                                   , instanceInfo.modelGuid
															   , i + 1
															   , new ObjectAction( null, ObjectInfo.OBJECTINFO_EMPTY );
				ammoAdded( ammo );
			}
	}

	private function ammoAddedEvent(e:GunEvent):void {
		var ammo:Ammo = e.data1 as Ammo;
		ammoAdded( ammo );
	}
	
	private function ammoAdded( $ammo:Ammo ):void 
	{
		var actionItem:ObjectAction = new ObjectAction( null,
														"fire",
														$ammo.guid + ".png",
														"Fire " + $ammo.guid );
		actionItem.ammoName = $ammo.name;
		Log.out( "Dragon.getDefaultSlotData - HACK TODO", Log.WARN );
		actionItem.instanceGuid = _guns[0].instanceInfo.instanceGuid;
	}

	private function getFreeSlot():int {
		return 0;
	}
	*/
	static private function loseControlHandler():void {
		VoxelModel.controlledModel.loseControl( VoxelModel.controlledModel );
		VoxelModel.controlledModel.takeControl( null, false );
	}
	
	import com.voxelengine.worldmodel.weapons.Gun;
	protected var _guns:Vector.<Gun> = new Vector.<Gun>;
	override protected function onChildAdded( $me:ModelEvent ):void
	{
		if ( !$me.vm ) {
			Log.out( "Dragon.onChildAdded - missing child model", Log.ERROR );
			return;
		}
		
		if ( !($me.vm is Gun) )	
			return;
			
		// make sure the gun belongs to us.
		var topmostInstanceGuid:String = $me.vm.instanceInfo.topmostInstanceGuid()
		if ( topmostInstanceGuid != instanceInfo.instanceGuid )
			return;
			
		_guns.push( $me.vm )
	}
	
}
}
