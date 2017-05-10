/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.Oxel
     
public final class OxelPool 
{
	private static var _initialPoolSize:int;
	private static var _growthValue:int;
	private static var _pools:Object = {};

	public static function initialize( $initialPoolSize:uint, $growthValue:uint ):void {
		_initialPoolSize = $initialPoolSize;
		_growthValue = $growthValue;
	}

	public static function poolGet( $type:uint ):Oxel {

		var poolId:int = poolForType($type);
		var pool:OxelTypePool = _pools[poolId];
		if ( !pool )
			pool = _pools[poolId] = new OxelTypePool(poolId, _initialPoolSize, _growthValue);
		return pool.poolGet()
	}

	public static function poolDispose( $oxel:Oxel ):void {
		var pool:OxelTypePool = _pools[$oxel.type];
		if ( !pool ) {
			Log.out( "OxelPool.poolDispose - no pool found for type: " + $oxel.type );
			return
		}
		pool.poolDispose( $oxel );
	}

	private static function poolForType( $type:uint ):int {
		if ( $type < 1000 )
			return 0;
		else if ( $type == 152 ) // Vines
			return 1;

		return 0;
	}

} 
}
