/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.pools.ParticlePool;
	import com.voxelengine.worldmodel.models.*;
	import flash.display3D.Context3D;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * The world model holds the active oxels
	 */
	public class Particle extends VoxelModel 
	{
		public function Particle( instanceInfo:InstanceInfo ) 
		{ 
			super( instanceInfo );
		}
		
		override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
			super.init( $mi, $vmm );
		}

		override public function update(context:Context3D, elapsedTimeMS:int):void 
		{
			super.update(context, elapsedTimeMS);
		}
		
		// Since these stick around in the pools, we dont want to fully release them.
		override public function release():void 
		{
			//Log.out( "Particle.release - guid: " + instanceInfo.instanceGuid );
			dead = false;
			ParticlePool.poolDispose( this );
		}
		
	}
}
