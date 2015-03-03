package com.voxelengine.worldmodel.scripts 
{
import flash.geom.Vector3D;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.VoxelModel;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.events.ImpactEvent;

/**
 * ...
 * @author Bob
 */

 
public class FireScript extends ImpactScript 
{
	
	public function FireScript( $ammo:Ammo ) 
	{
		super( $ammo );
	}
	
	override public function impact( $wsLoc:Vector3D ):void
	{
		var vm:VoxelModel = Globals.modelGet( instanceGuid );
		if ( vm )
			vm.dead = true;
		
		Log.out( "FireScript.impact - at x: " + $wsLoc.x + " y: " + $wsLoc.y + "  z: " + $wsLoc.z );
		
		ImpactEvent.dispatch( new ImpactEvent( ImpactEvent.DFIRE, $wsLoc, _ammo.grain * 4, _ammo.grain * 2, instanceGuid ) );
		
		impactSound();
	}
}
}