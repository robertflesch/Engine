package com.voxelengine.worldmodel.scripts 
{
import com.voxelengine.Log;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.worldmodel.weapons.Ammo;
import flash.geom.Vector3D;
/**
 * ...
 * @author Bob
 */


public class ImpactScript extends Script
{

	protected var _ammo:Ammo;

	public function ImpactScript( $params:Object ) {
		super( $params );
		Log.out( "ImpactScript - how are params passed in?")
		$params //_ammo = $ammo;
	}

	public function impact( wsLoc:Vector3D ):void
	{
		throw new Error( "ImpactScript.impact - ERROR this function needs to be overridden" );
	}

	protected function impactSound():void {
		SoundCache.playSound( _ammo.impactSound )
	}
}

}