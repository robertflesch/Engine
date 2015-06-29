/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

import flash.utils.getTimer;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.FlowInfo;
     
public final class FlowPool
{ 
	private static var _currentPoolSize:uint; 
	private static var GROWTH_VALUE:uint; 
	private static var _counter:uint; 
	private static var _pool:Vector.<FlowInfo>; 
	
	static public function remaining():uint { return _counter; }
	static public function totalUsed():uint { return _currentPoolSize - _counter; }
	static public function total():uint { return _currentPoolSize; }

	public static function initialize( maxPoolSize:uint, growthValue:uint ):void 
	{ 
		_currentPoolSize = maxPoolSize; 
		GROWTH_VALUE = growthValue; 
		_counter = maxPoolSize; 
 
		var i:uint = maxPoolSize; 
		 
		_pool = new Vector.<FlowInfo>(_currentPoolSize); 
		while( --i > -1 ) 
			_pool[i] = new FlowInfo(); 
	} 
	 
	public static function poolGet():FlowInfo 
	{ 
		if ( _counter > 0 ) 
			return _pool[--_counter];
			 
		Log.out( "FlowPool.poolGet - Allocating more FlowInfo: " + _currentPoolSize );
		var timer:int = getTimer();

		_currentPoolSize += GROWTH_VALUE;
		_pool = null
		_pool = new Vector.<FlowInfo>(_currentPoolSize);
		for ( var newIndex:int = 0; newIndex < GROWTH_VALUE; newIndex++ )
			_pool[newIndex] = new FlowInfo();
			
		_counter = newIndex - 1; 
		
		Log.out( "FlowPool.poolGet - Done allocating more FlowInfo: " + _currentPoolSize  + " took: " + (getTimer() - timer) );
		return poolGet(); 
	} 

	public static function poolReturn( $flowInfo:FlowInfo ):void 
	{ 
		if ( !$flowInfo )
		{
			Log.out( "FlowPool.poolReturn - displosed $flowInfo is NULL", Log.WARN );
			return;
		}
		$flowInfo.reset();	
		_pool[_counter++] = $flowInfo; 
	} 
} 
}

