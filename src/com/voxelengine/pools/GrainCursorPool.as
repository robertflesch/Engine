/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

import flash.utils.getTimer;

import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.GrainCursor
     
public final class GrainCursorPool 
{ 
	private static var _currentPoolSize:uint; 
	private static var _growthValue:uint; 
	private static var _counter:uint; 
	private static var _pool:Vector.<GrainCursor>; 
	private static var _currentGrainCursor:GrainCursor; 
	
	static public function remaining():uint { return _counter; }
	static public function total():uint { return _currentPoolSize; }
	static public function totalUsed():uint { return _currentPoolSize - _counter; }

	public static function initialize( maxPoolSize:uint, growthValue:uint ):void 
	{ 
		_currentPoolSize = maxPoolSize; 
		_growthValue = growthValue; 
		_counter = maxPoolSize; 
		 
		var i:uint = maxPoolSize; 
		 
		_pool = new Vector.<GrainCursor>(_currentPoolSize); 
		while( --i > -1 ) 
			_pool[i] = new GrainCursor(); 
	} 
	 
	public static function poolGet( boundingGrain:int ):GrainCursor 
	{ 
		if ( _counter > 0 ) {
			_currentGrainCursor = _pool[--_counter];
			_currentGrainCursor.bound = boundingGrain;
			return _currentGrainCursor; 
		}
			 
		Log.out( "GrainCursorPool.poolGet - Allocating more GrainCursors: " + _growthValue );
		var timer:int = getTimer();

		_currentPoolSize += _growthValue;
		_pool = null;
		_pool = new Vector.<GrainCursor>(_currentPoolSize);
		for ( var newIndex:int = 0; newIndex < _growthValue; newIndex++ )
		{
			_pool[newIndex] = new GrainCursor();
		}
		
		_counter = newIndex - 1; 
		_growthValue *= 2;
		
		Log.out( "GrainCursorPool.poolGet - Done allocating more GrainCursors, total size: " + _currentPoolSize  + " took: " + (getTimer() - timer) );
		return poolGet(boundingGrain); 
		 
	} 

	public static function poolDispose(disposedGrainCursor:GrainCursor):void 
	{ 
		disposedGrainCursor.reset();
		_pool[_counter++] = disposedGrainCursor; 
	} 
} 
}

