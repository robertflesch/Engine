/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.scripts
{
/**
 * ...
 * @author Bob
 */
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.worldmodel.models.makers.ModelMaker;

import flash.media.Sound;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.media.SoundChannel;
import flash.net.URLRequest;
import flash.geom.Vector3D;

import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.events.WeaponEvent;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.weapons.Bomb;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.InstanceInfo;

public class BombScript extends Script 
{
	//private var _channel:SoundChannel;
	protected var _soundFile:String = "BombDrop.mp3";		
	
	public function BombScript( $params:Object ) {
		super( $params );
		var _bulletSize:int = 2;
		if ( $params && $params.bulletSize )
			_bulletSize = $params.bulletSize;

		addKeyboardListeners();
		//SoundCache.getSound( _soundFile ); // Preload the animationSound file
		SoundEvent.create( ModelBaseEvent.REQUEST, 0, _soundFile, null, Globals.isGuid( _soundFile ) );
		WeaponEvent.addListener( WeaponEvent.FIRE, onWeaponEventDrop, false, 0, true );
	}
	
	override public function dispose():void
	{
		//if ( _channel )
		//	_channel.stop();
	}
	
	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("BombScript.ioErrorHandler: " + event);
	}		
	
	private function addKeyboardListeners() : void
	{
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, onKeyPressed);
	}

	private function onKeyPressed( e : KeyboardEvent) : void
	{
		if ( Keyboard.B == e.keyCode )
		{
			drop();
		}
	}
	
	private function drop():void
	{
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, onKeyPressed);
		
		//var snd:Sound = SoundCache.getSound( _soundFile );
		//_channel = snd.play();
		SoundCache.playSound( _soundFile );
		
		var bomb:Bomb = Region.currentRegion.modelCache.instanceGet( instanceGuid ) as Bomb;
		if ( bomb )
		{
			var ship:VoxelModel = bomb.instanceInfo.controllingModel;
			if ( ship )
			{
				createReplacementBomb( bomb.instanceInfo.clone() , ship.instanceInfo.instanceGuid );
		
				ship.modelInfo.childDetach( bomb, ship );

				bomb.instanceInfo.addTransform( 0, -5, 0, ModelTransform.INFINITE_TIME, ModelTransform.VELOCITY, "Gravity" );
				bomb.instanceInfo.addTransform( 0, 0, 0, 10000, ModelTransform.LIFE );
			}
			else
				trace( "BombScript.drop - ship not found: " + bomb.instanceInfo.controllingModel );
		}
		else
			trace( "BombScript.drop - bomb not found: " + instanceGuid );
	}
	
	public function createReplacementBomb( ii:InstanceInfo, shipGuid:String ):void
	{
		// this was important, dont recall why
		var newShip:VoxelModel = Region.currentRegion.modelCache.instanceGet( shipGuid );
		ii.controllingModel = newShip;

		new ModelMaker( ii );
	}
	
	
	public function onWeaponEventDrop( $event:WeaponEvent ):void 
	{
		if ( instanceGuid != $event.gun.instanceInfo.instanceGuid )
		{
			trace( "onWeaponEvent: BombScript - ignoring event for someone else" + $event + " guid: " + instanceGuid );
			return;
		}
		
		drop();	
	}
}
}