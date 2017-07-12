/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
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
		Log.out( "ImpactScript - how are params passed in?");
		//noinspection BadExpressionStatementJS
		$params; //_ammo = $ammo;
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