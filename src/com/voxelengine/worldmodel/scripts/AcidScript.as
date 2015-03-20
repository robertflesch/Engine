package com.voxelengine.worldmodel.scripts 
{
import flash.geom.Vector3D;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.events.ImpactEvent;


/**
 * ...
 * @author Bob
 */

 
public class AcidScript extends ImpactScript 
{
	
	public function AcidScript( $ammo:Ammo ) 
	{
		super( $ammo );
	}
	
	override public function impact( $wsLoc:Vector3D ):void
	{
		var vm:VoxelModel = Globals.modelGet( instanceGuid );
		if ( vm )
			vm.dead = true;

		Log.out( "AcidScript.impact - at x: " + $wsLoc.x + " y: " + $wsLoc.y + "  z: " + $wsLoc.z );
		
		ImpactEvent.dispatch( new ImpactEvent( ImpactEvent.ACID, $wsLoc, _ammo.grain * 4, _ammo.grain * 2, instanceGuid ) );
		
		impactSound();
	}
}
}