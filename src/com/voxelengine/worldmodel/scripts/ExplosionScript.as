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

 
public class ExplosionScript extends ImpactScript 
{
	
	public function ExplosionScript( $ammo:Ammo ) 
	{
		super( $ammo );
	}
	
	override public function impact( $wsLoc:Vector3D ):void
	{
		var vm:VoxelModel = Globals.g_modelManager.getModelInstance( instanceGuid );
		if ( vm )
			vm.instanceInfo.dead = true;
		
		Log.out( "ExplosionScript.impact - at x: " + $wsLoc.x + " y: " + $wsLoc.y + "  z: " + $wsLoc.z );
		
		Globals.g_app.dispatchEvent( new ImpactEvent( ImpactEvent.EXPLODE, $wsLoc, _ammo.grain * 4, _ammo.grain * 2, instanceGuid ) );
		
		impactSound();
	}
}

}