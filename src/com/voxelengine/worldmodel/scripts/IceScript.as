package com.voxelengine.worldmodel.scripts 
{
import flash.geom.Vector3D;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.events.ImpactEvent;
	import com.voxelengine.worldmodel.Region;


/**
 * ...
 * @author Bob
 */

 
public class IceScript extends ImpactScript 
{
	
	public function IceScript( $ammo:Ammo ) 
	{
		super( $ammo );
	}
	
	override public function impact( $wsLoc:Vector3D ):void
	{
		var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( instanceGuid );
		if ( vm )
			vm.dead = true;

		Log.out( "IceScript.impact - at x: " + $wsLoc.x + " y: " + $wsLoc.y + "  z: " + $wsLoc.z );
		
		ImpactEvent.dispatch( new ImpactEvent( ImpactEvent.DICE, $wsLoc, _ammo.grain * 4, _ammo.grain * 2, instanceGuid ) );
		
		impactSound();
	}
}
}