/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.events.WeaponEvent;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;	

/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class Gun extends ControllableVoxelModel 
{
	protected var _id:int;
	protected var _series:int;
	static protected var _armory:Vector.<String> = new Vector.<String>;
	protected var _ammo:Ammo;
	static protected var _reloadSpeed:Number;

	public function get ammo():Ammo { return _ammo; }
	public function set ammo( $ammo:Ammo ):void { _ammo = $ammo; }
	static public function get armory():Vector.<String>  { return _armory; }
	
	static public function get reloadSpeed():Number { return _reloadSpeed; }
	//Barrel
	//Stand
	//Sight
	public function Gun( instanceInfo:InstanceInfo ) 
	{ 
		super( instanceInfo );
		// give the gun a unique series
		_series = _id++;
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		
		var centerLoc:int = 2 << ( $mi.grainSize - 2);
		calculateCenter( centerLoc );
		
		// Process the gun specific info
		var script:Script = _instanceInfo.addScript( "FireProjectileScript", true );
		//script.processClassJson( modelInfo );
	}
	
	public function fire():void
	{
		Globals.g_app.dispatchEvent( new WeaponEvent( WeaponEvent.FIRE, instanceInfo.instanceGuid, ammo ) );			
	}
	
	override protected function processClassJson():void {
		super.processClassJson();
		
		if ( modelInfo.info && modelInfo.info.gun )
			var gunInfo:Object = modelInfo.info.gun;
		else {
			Log.out( "Gun.processClassJson - Gun section not found: " + modelInfo.dbo.toString(), Log.ERROR );
			return;
		}
		
		if ( gunInfo.reloadSpeed )
			_reloadSpeed = gunInfo.reloadSpeed;
			
		if ( gunInfo.ammos ) {
			AmmoEvent.addListener( ModelBaseEvent.RESULT, result );
			AmmoEvent.addListener( ModelBaseEvent.ADDED, result );
			AmmoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, resultFailed );
			var ammosJson:Object = gunInfo.ammos;
			for each ( var ammoInfo:Object in ammosJson )
				request( ammoInfo.name );
		}
//			if ( _armory.length )
//				_ammo = _armory[0];
	}

	static public function buildExportObject( obj:Object ):void {
		// For now just use the existing gun data
		ControllableVoxelModel.buildExportObject( obj )
		//var gunData:Object = new Object();
		//gunData.reloadSpeed = _reloadSpeed;
		//
		//var oa:Vector.<Object> = new Vector.<Object>();
		//var ammosJson:Object = modelInfo.dbo.gun.ammos;
		//for each ( var ammoInfo:Object in ammosJson )
			//oa.push( { name: ammoInfo.name } );
//
		//gunData.ammos = oa;
//		obj.gun = gunData;
	}

	public function request( $ammoName:String ):void {
		
		//public function PersistanceEvent( $type:String, $series:int, $table:String, $guid:String, $dbo:DatabaseObject = null, $data:* = null, $format:String = URLLoaderDataFormat.TEXT, $other:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false );
		_armory.push( $ammoName );
		AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST, _series, $ammoName, null ) );
	}

	private function result(e:AmmoEvent):void 
	{
		if ( _series == e.series )
			_armory.push( e.ammo );
	}
	
	private function resultFailed(e:AmmoEvent):void 
	{
		if ( _series == e.series )
			Log.out( "Gun.resultFailed - No ammo information found for name: " + e.name );
	}
	
	override public function update(context:Context3D, elapsedTimeMS:int):void 
	{
		super.update(context, elapsedTimeMS);
	}
	
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
