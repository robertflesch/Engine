/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import flash.events.Event
import flash.events.EventDispatcher;

import com.voxelengine.Log
import com.voxelengine.worldmodel.weapons.Ammo
import com.voxelengine.worldmodel.weapons.Gun;
/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class WeaponEvent extends Event
{
	static public const INVALID:String					= "INVALID"
	static public const FIRE:String 					= "FIRE"
	
	private var _ammo:Ammo
	private var _gun:Gun
	
	public function get ammo():Ammo { return _ammo }
	public function get gun():Gun { return _gun }
	
	public function WeaponEvent( $type:String, $gun:Gun, $ammo:Ammo, $bubbles:Boolean = true, $cancellable:Boolean = false ) {
		super( $type, $bubbles, $cancellable )
		_ammo = $ammo
		if ( null == $ammo )
			Log.out( "WeaponEvent.construction - NO AMMO DEFINED", Log.ERROR )
		_gun = $gun
		if ( null == $gun )
			Log.out( "WeaponEvent.construction - NO AMMO DEFINED", Log.ERROR )
	}
	
	public override function clone():Event {
		return new WeaponEvent(type, _gun, _ammo, bubbles, cancelable)
	}
   
	public override function toString():String {
		return formatToString("WeaponEvent", "gun", "ammo" );
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher()

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference )
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture )
	}

	static public function dispatch( $event:WeaponEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event )
	}
	
	///////////////// Event handler interface /////////////////////////////
	
}
}
