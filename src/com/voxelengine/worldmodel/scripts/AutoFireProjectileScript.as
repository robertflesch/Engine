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

import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.worldmodel.weapons.Ammo;
	import com.voxelengine.worldmodel.weapons.Gun;
	import flash.events.TimerEvent;
	import flash.events.KeyboardEvent;
	import flash.utils.Timer;
	import flash.ui.Keyboard;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.WeaponEvent;
	import com.voxelengine.worldmodel.scripts.FireProjectileScript;

	
	public class AutoFireProjectileScript extends FireProjectileScript 
	{

		
		public function AutoFireProjectileScript($params:Object ) {
			super ( $params );
			var _repeatTime:int = 5000;
			var _timer:flash.utils.Timer = new Timer(_repeatTime, 0);
			_timer.addEventListener( TimerEvent.TIMER
					, function() : void  { Globals.active ? fire():null }
					, false
					, 0
					, true );
			//_timer.start();

			//_ammo.accuracy = 0.000;
			//_ammo.velocity = 1000;

			VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN
					, function(e:KeyboardEvent) : void  { Keyboard.F == e.keyCode ? fire():null }
					, false
					, 0
					, false );		// true here causes the fire ability to be lost, is it getting garbage collected?
		}

		private function fire():void
		{
			trace( "AutoFireProjectileScript.fire" );
			var ammo:Ammo = (vm as Gun).armory.currentSelection();
			WeaponEvent.dispatch( new WeaponEvent( WeaponEvent.FIRE, vm as Gun, ammo ) );
			//_owner.explode(1);
		}
	}
}