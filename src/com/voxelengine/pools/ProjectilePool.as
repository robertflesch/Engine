/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

import com.voxelengine.Log
import com.voxelengine.events.AmmoEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.worldmodel.weapons.Projectile
     
public final class ProjectilePool 
{ 
	private static var _currentPoolSize:int;
	private static var _growthValue:int;
	private static var _pools:Object = {};
	
	public static function initialize( $initialPoolSize:uint, $growthValue:uint ):void { 
		_currentPoolSize = $initialPoolSize;
		_growthValue = $growthValue;
		AmmoEvent.addListener( ModelBaseEvent.ADDED, ammoAdded )
	} 
	
	static private function ammoAdded(e:AmmoEvent):void {
		_pools[e.ammo.name] = new ProjectilePoolType( e.ammo.oxelType, _currentPoolSize, _growthValue )
	}
	
	public static function poolGet( ammo:Ammo ):Projectile { 
		var pool:ProjectilePoolType = _pools[ammo.name];
		if ( !pool )
			pool = _pools[ammo.name] = new ProjectilePoolType(ammo.oxelType, _currentPoolSize, _growthValue);
		return pool.poolGet() 
	} 

	public static function poolDispose( $disposedProjectile:Projectile):void { 
		var name:String = $disposedProjectile.ammo.name;
		var pool:ProjectilePoolType = _pools[name];
		if ( !pool ) {
			Log.out( "ProjectilePool.poolDispose - no pool found for name: " + name + " ammo: " + $disposedProjectile.ammo.toString() );
			return
		}
		pool.poolDispose( $disposedProjectile )
	} 
}
}