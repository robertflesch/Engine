/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.worldmodel.models.types.ControllableVoxelModel;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.events.KeyboardEvent;
import flash.ui.Keyboard;	

import com.voxelengine.Log;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.GunEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WeaponEvent;
import com.voxelengine.worldmodel.inventory.FunctionRegistry;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.scripts.Script;

/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class Gun extends ControllableVoxelModel 
{
	protected var _series:int			= 0;
	protected var _armory:Armory 		= new Armory();
	protected var _reloadSpeed:Number 	= 1000;
	protected var _weaponType:String 	= Armory.DEFAULT_WEAPON_TYPE;
	private var _ammoLoaded:Boolean;

	public function get weaponType():String  { return _weaponType; }

	public function get armory():Armory  { return _armory; }
	public function armoryAddAmmo( $ammo:Ammo ):void  { _armory.add( $ammo ); modelInfo.changed = true; }
	public function armoryRemoveAmmo( $ammo:Ammo ):void  { _armory.remove( $ammo ); modelInfo.changed = true; }
	public function get reloadSpeed():Number { return _reloadSpeed; }
	//Barrel
	//Stand
	//Sight
	public function Gun( instanceInfo:InstanceInfo ) { 
		//Log.out( "Gun instanceInfo: " + instanceInfo,Log.WARN );
		super( instanceInfo );
		// give the gun a unique series
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		if ( $mi.oxelPersistence && $mi.oxelPersistence.bound ) {
			var centerLoc:int = 2 << ( $mi.oxelPersistence.bound - 2);
			calculateCenter( centerLoc );
		}
		
		// Process the gun specific info
		var script:Script = _instanceInfo.addScript( "FireProjectileScript", true );
		//script.processClassJson( modelInfo );
			
		FunctionRegistry.functionAdd( fire, "fire" );
		InventorySlotEvent.addListener( InventorySlotEvent.DEFAULT_REQUEST, defaultGunInventory );
	}
	
	private function defaultGunInventory(e:InventorySlotEvent):void 
	{
		if ( instanceInfo.instanceGuid == e.instanceGuid ) {
			var ammoList:Vector.<Ammo> = _armory.getAmmoList();
			for each ( var ammo:Ammo in ammoList ) {
				var oa:ObjectAction = new ObjectAction( null, "fire", ammo.guid + ".png", "Fire" );
				oa.ammoName = ammo.name;
				oa.instanceGuid = instanceInfo.instanceGuid;
				InventorySlotEvent.create( InventorySlotEvent.CHANGE, e.ownerGuid, instanceInfo.instanceGuid, -1, oa );
			}
		}
	}
	
	public function fire( $name:String ):void {
		var ammo:Ammo = _armory.getAmmoByName( $name );
		WeaponEvent.dispatch( new WeaponEvent( WeaponEvent.FIRE, this, ammo ) );			
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.gun = {};

		modelInfo.dbo.gun.weaponType = _weaponType;
		modelInfo.dbo.gun.reloadSpeed = _reloadSpeed;
		var ammo:Vector.<Ammo> = _armory.getAmmoList();
		if ( ammo.length ) {
			modelInfo.dbo.gun.ammos = [];
			for (var index:int = 0; index < ammo.length; index++) {
				modelInfo.dbo.gun.ammos.push({guid: ammo[index].guid})
			}
		}
		if ( _ammoCount ) {
			modelInfo.changed = true;
		}
	}

	private var _ammoCount:int;
	override protected function processClassJson():void {
		super.processClassJson();
		
		if ( modelInfo.dbo.gun )
			var gunInfo:Object = modelInfo.dbo.gun;
		else {
			Log.out( "Gun.processClassJson - Gun section not found: " + modelInfo.dbo.toString(), Log.WARN );
			return;
		}

		if ( gunInfo.weaponType )
			_weaponType = gunInfo.weaponType;

		if ( gunInfo.reloadSpeed )
			_reloadSpeed = gunInfo.reloadSpeed;

		if ( gunInfo.ammos ) {
			AmmoEvent.addListener( ModelBaseEvent.RESULT, result );
			AmmoEvent.addListener( ModelBaseEvent.ADDED, result );
			AmmoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, resultFailed );
			var ammosJson:Object = gunInfo.ammos;
			for each ( var ammoInfo:Object in ammosJson ) {
				var ae:AmmoEvent = new AmmoEvent( ModelBaseEvent.REQUEST, _series, ammoInfo.guid, null );
				_series = ae.series;
				AmmoEvent.dispatch( ae );
				_ammoCount++;
			}
		}
	}
	
	private function result(e:AmmoEvent):void {
		//Log.out( "Gun.result - _series ("+_series+") == e.series("+e.series+ ")", Log.WARN );
		if ( _series == e.series ) {
			_ammoCount--;
			_armory.add( e.ammo );
			GunEvent.dispatch( new GunEvent( GunEvent.AMMO_ADDED, instanceInfo.modelGuid, e.ammo ) );
			ifLoadCompleteThenBroadcast();
		}
	}
	
	private function resultFailed(e:AmmoEvent):void {
		if ( _series == e.series ) {
			_ammoCount--;
			Log.out( "Gun.resultFailed - No ammo information found for guid: " + e.guid, Log.ERROR );
			ifLoadCompleteThenBroadcast();
		}
	}
	
	private function ifLoadCompleteThenBroadcast():void {
		if ( 0 == _ammoCount ) {
			GunEvent.dispatch(new GunEvent(GunEvent.AMMO_LOAD_COMPLETE, instanceInfo.modelGuid, instanceInfo.instanceGuid));
			AmmoEvent.removeListener( ModelBaseEvent.RESULT, result );
			AmmoEvent.removeListener( ModelBaseEvent.ADDED, result );
			AmmoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, resultFailed );
			save();
		}

	}
	
	// When is this used?
	override protected function onKeyDown(e:KeyboardEvent):void 
	{
		switch (e.keyCode) {
			case 87: case Keyboard.UP: 
				instanceInfo.addNamedTransform( _turnRate, 0, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, "rotation" );			
				break;
			case 83: case Keyboard.DOWN: 
				instanceInfo.addNamedTransform( -_turnRate, 0, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, "rotation" );			
				break;
			case 65: case Keyboard.LEFT: 
				instanceInfo.addNamedTransform( 0, _turnRate, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, "rotation" );			
				break;
			case 68: case Keyboard.RIGHT: 
				instanceInfo.addNamedTransform( 0, -_turnRate, 0, ModelTransform.INFINITE_TIME, ModelTransform.ROTATION, "rotation" );			
				break;
		}
	}
	
	// When is this used?
	override protected function onKeyUp(e:KeyboardEvent):void 
	{
		switch (e.keyCode) {
			case 87: case Keyboard.UP:
			case 83: case Keyboard.DOWN:
			case 65: case Keyboard.LEFT: 
			case 68: case Keyboard.RIGHT: 
				instanceInfo.addNamedTransform( 0, 0, 0, 0.1, ModelTransform.ROTATION, "rotation" );			
				break;
		}
	}
}
}
