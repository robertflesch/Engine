/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

public final class PoolManager
	{ 
		// this uses up 3.6 gig of memory
		//private static const INITIAL_POOL_SETTINGS:int = 1200000; // crashes app
		// this uses up ?? gig of memory
		//private static const INITIAL_POOL_SETTINGS:int = 600000; // 2.33 gig  22 seconds
		// this uses up 1.2 gig of memory
		//private static const INITIAL_POOL_SETTINGS:int = 400000; // ~15.6 seconds
		// USE THIS FOR ISLANDS (g12)
		// this uses up 687 meg of memory
		//private static const INITIAL_POOL_SETTINGS:int = 250000;
		// this uses up 424 meg of memory (565 meg now with lighting on AlexaIsland)
		// This is minimum kickstarter setting
		//private static const INITIAL_POOL_SETTINGS:int = 100000;  //3.5 seconds
		//private static const INITIAL_POOL_SETTINGS:int = 50000;
		private static const INITIAL_POOL_SETTINGS:int = 30000;
		// this uses up 157 meg of memory
		//private static const INITIAL_POOL_SETTINGS:int = 1000;
		
		public function PoolManager() {
			ChildOxelPool.initialize( INITIAL_POOL_SETTINGS, INITIAL_POOL_SETTINGS* 2/8 );
			QuadPool.initialize( INITIAL_POOL_SETTINGS * 4, INITIAL_POOL_SETTINGS/2 );
			QuadsPool.initialize( INITIAL_POOL_SETTINGS * 1.7, INITIAL_POOL_SETTINGS/6 );
			LightInfoPool.initialize( INITIAL_POOL_SETTINGS * 4, INITIAL_POOL_SETTINGS ); // 10
			LightingPool.initialize( INITIAL_POOL_SETTINGS * 4, INITIAL_POOL_SETTINGS ); // 10
			FlowInfoPool.initialize( INITIAL_POOL_SETTINGS * 10, INITIAL_POOL_SETTINGS );
			NeighborPool.initialize( INITIAL_POOL_SETTINGS * 2.5, INITIAL_POOL_SETTINGS );
			VertexIndexBuilderPool.initialize( INITIAL_POOL_SETTINGS/50, INITIAL_POOL_SETTINGS/200 );
			// These two should always be the same
			GrainCursorPool.initialize( INITIAL_POOL_SETTINGS * 6, INITIAL_POOL_SETTINGS * 2 );
			OxelPool.initialize( INITIAL_POOL_SETTINGS * 6, INITIAL_POOL_SETTINGS );
			ParticlePool.initialize( Math.max( 10, INITIAL_POOL_SETTINGS/10000), Math.max( 10, INITIAL_POOL_SETTINGS/10000) );
		}
	}

}

