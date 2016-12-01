/*==============================================================================
Copyright 2011-2016 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.scripts 
{
import flash.geom.Vector3D;
import flash.geom.Matrix3D;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.ProjectileEvent;
import com.voxelengine.events.WeaponEvent;
import com.voxelengine.pools.ProjectilePool;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.worldmodel.weapons.*;
import com.voxelengine.worldmodel.models.ModelTransform;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class FireProjectileScript extends Script
{
	public function FireProjectileScript()
	{
		WeaponEvent.addListener( WeaponEvent.FIRE, onFire );
		ProjectileEvent.addListener( ProjectileEvent.PROJECTILE_CREATED, createProjectile );
	}

	// TODO - Is there anyway that this is removed? and listeners are removed?

	public function onFire( $event:WeaponEvent ):void
	{
		// This gun listens for a WeaponEvent.FIRE, that means that a weapon has been fired
		// make sure its the owner of this weapon that fired it. so that correct position info, etc can be determined
		if ( instanceGuid != $event.gun.instanceInfo.instanceGuid )
			return Log.out( "FireProjectileScript.onFire - ignoring event for someone else" + $event + " instanceGuid: " + instanceGuid );

		// first we calculate the location of the end of the barrel
		// The guns position is in ModelSpace
		var gunModel:Gun = $event.gun;
		if ( !gunModel )
			return Log.out( "FireProjectileScript.onFire - Gun model is NULL", Log.ERROR );

		//Log.out( "FireProjectileScript.onFire - EVENT: " + WeaponEvent.FIRE );


		var dr:Vector3D;
		var gunWSLocation:Vector3D
		if ( 0 ) {
			// This takes the model space position of the gun, and uses the cumulative model rotation
			gunWSLocation = gunModel.wsPositionGet();
			dr = gunModel.rotationGetCummulative();
			dr.normalize();
		} else {
			// This takes the model space position of the gun, and uses the parent model rotation
			var tmm:VoxelModel = gunModel.topmostControllingModel();
			gunWSLocation = tmm.modelToWorld(gunModel.msPositionGet());
			dr = tmm.instanceInfo.lookAtVector(1);
		}


		// dont handle event directly, since then I will generate event at same times as everyone else.
		var pe:ProjectileEvent = new ProjectileEvent( ProjectileEvent.PROJECTILE_SHOT );

		Log.out( "FireProjectileScript.onFire - dr: " + dr + " loc: " + gunWSLocation );

		//throw new Error( "FireProjectileScript.onFire - what to do here" );
		pe.ammo = $event.ammo;
		pe.owner = gunModel.instanceInfo.instanceGuid;
		pe.position = gunWSLocation;
		pe.direction = dr;

		Log.out( "FireProjectileScript.onFire - ProjectileEvent: " + pe );
		ProjectileEvent.dispatch( pe );
	}


	static public function createProjectile( pe:ProjectileEvent ):void {
		Log.out( "FireProjectileScript.createProjectile - ProjectileEvent: " + pe );
		SoundCache.playSound( pe.ammo.launchSound )
		/*
		var ownerGuid:String = pe.owner;
		var gunModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( ownerGuid );
		var chain:Vector.<VoxelModel> = new Vector.<VoxelModel>()
		gunModel.getModelChain( chain )
		var worldSpaceMatrixForGun:Matrix3D = VoxelModel.getWorldSpacePositionInChain( chain )
		pe.position = worldSpaceMatrixForGun.position
		Log.out( "FireProjectileScript.createProjectile pe.position: " + pe.position )
		// More work here, do I really need to pass this direction and velocity with ProjectileEvent?
		// Or when is best time to do it? When I fire or here?
//			Log.out( "ProjectileScript.createProjectile - NOT DONE HERE 9.23.15", Log.ERROR );
		*/
		var gunModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( pe.owner );
		var cm:VoxelModel = gunModel.topmostControllingModel();
		var parentVelocity:Vector3D = cm.instanceInfo.worldSpaceMatrix.deltaTransformVector( cm.instanceInfo.velocityGet );
		Log.out( "FireProjectileScript.createProjectile - parentVelocity: " + parentVelocity );

		if ( 1 == pe.ammo.type )
				bulletPool( pe, parentVelocity );
		else if ( 2 == pe.ammo.type ) {
			var count:int = pe.ammo.count;
			for ( var i:int = 0; i < count; i++ )
				bulletPool( pe, parentVelocity );
		}
	}

	static private function bulletPool( pe:ProjectileEvent, parentVelocity:Vector3D ):void
	{
		var pm:Projectile = ProjectilePool.poolGet( pe.ammo );
		// Arrg - particles just contain place holder oxel the first time when first created.
		// So any changes are wiped away once the actual model loads.
		// may be fixed by pool changes.

		pm.instanceInfo.usesCollision = true;
		pm.ammo = pe.ammo;

		var grainChange:int = pe.ammo.grain - pm.grain;
		if ( !pm.modelInfo || !pm.modelInfo.data ) {
			Log.out( "FireProjectileScript.bulletPool Didnt find !pm.modelInfo || !pm.modelInfo.data" );
			return;
		}
		if ( 0 < grainChange )
			pm.changeGrainSize( grainChange );
		if ( pm.modelInfo.data.oxel.type != pe.ammo.oxelType )
			pm.modelInfo.data.oxel.changeAllButAirToType( pe.ammo.oxelType );

		pm.instanceInfo.positionSet = pe.position;
//			Log.out( "FireProjectileScript.bulletPool ProjectileEvent: " + pe );
		var dr:Vector3D = pe.direction.clone();
		var accuracy:Number = pe.ammo.accuracy;

		if ( 0.5 < Math.random() )
			dr.x += Math.random() * accuracy;
		else
			dr.x -= Math.random() * accuracy;

		if ( 0.5 < Math.random() )
			dr.y += Math.random() * accuracy;
		else
			dr.y -= Math.random() * accuracy;

		if ( 0.5 < Math.random() )
			dr.z += Math.random() * accuracy;
		else
			dr.z -= Math.random() * accuracy;

		dr.scaleBy( pe.ammo.velocity );

		if ( parentVelocity )
		{
			//Log.out( "FireProjectileScript.bulletPool PRE - direction: " + dr + " directionMag: " + dr.length + "  parentVelocity: " + parentVelocity + " parentVelocityMag: " + parentVelocity.length );
			var drPlus:Vector3D = pe.direction.clone();
			drPlus.normalize();
			drPlus.scaleBy( parentVelocity.length * 100 );
			//Log.out( "FireProjectileScript.bulletPool PLS - direction: " + drPlus + " directionMag: " + drPlus.length );
			dr = dr.add( drPlus );
			//Log.out( "FireProjectileScript.bulletPool PST - direction: " + dr + " directionMag: " + dr.length + "  parentVelocity: " + parentVelocity + " parentVelocityMag: " + parentVelocity.length );
		}
		else
			Log.out( "FireProjectileScript.bulletPool - direction: " + dr );

		pm.instanceInfo.addTransform( dr.x, dr.y, dr.z, ModelTransform.INFINITE_TIME, ModelTransform.POSITION, Projectile.PROJECTILE_VELOCITY );
		//pm.instanceInfo.addTransform( 0, Globals.GRAVITY, 0, ModelTransform.INFINITE_TIME, ModelTransform.POSITION, "Gravity" );
		pm.instanceInfo.addTransform( 0, 0, 0, pe.ammo.life, ModelTransform.LIFE );
		//pm.instanceInfo.addTransform( 0, 0, 0.1, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION_STRING );

		// add this particle to the system, it will get returned to pool when it dies.
		Region.currentRegion.modelCache.add( pm );
	}
}
}