/*==============================================================================
 Copyright 2011-2016 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/


package com.voxelengine.pools {
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Lighting;

import flash.utils.getTimer;

public class LightInfoPool {
private static var _currentPoolSize:uint;
private static var GROWTH_VALUE:uint;
private static var _counter:uint = 0;
private static var _pool:Vector.<LightInfo>;

static public function remaining():uint { return _counter; }
static public function totalUsed():uint { return _currentPoolSize - _counter; }
static public function total():uint { return _currentPoolSize; }

public static function initialize( maxPoolSize:uint, growthValue:uint ):void
{
    _currentPoolSize = maxPoolSize;
    GROWTH_VALUE = growthValue;
    _counter = maxPoolSize;

    var i:uint = maxPoolSize;

    _pool = new Vector.<LightInfo>(_currentPoolSize);
    while( --i > -1 )
        _pool[i] = new LightInfo();
}

public static function poolGet():LightInfo
{
    if ( _counter > 0 ) {
        return _pool[--_counter];
    }

    Log.out( "LightInfoPool.poolGet - Allocating more LightInfo: " + _currentPoolSize );
    var timer:int = getTimer();

    _currentPoolSize += GROWTH_VALUE;
    _pool = null
    _pool = new Vector.<LightInfo>(_currentPoolSize);
    for ( var newIndex:int = 0; newIndex < GROWTH_VALUE; newIndex++ )
    {
        _pool[newIndex] = new LightInfo();
    }
    _counter = newIndex - 1;

    Log.out( "LightInfoPool.poolGet - Done allocating more LightInfo: " + _currentPoolSize  + " took: " + (getTimer() - timer) );
    return poolGet();
}

public static function poolReturn( $disposedBrightness:LightInfo ):void
{
    if ( !$disposedBrightness )
    {
        Log.out( "LightInfoPool.poolReturn - displosedLightInfo is NULL" );
        return;
    }
    //                  setInfo( $ID:uint , $color:uint , $baseAttn:uint , $baseLightLevel:uint , $lightIs:Boolean = false ):void {
    $disposedBrightness.setInfo( 0, Lighting.DEFAULT_COLOR, Lighting.DEFAULT_ATTN, Lighting.DEFAULT_ILLUMINATION, false )

    _pool[_counter++] = $disposedBrightness;
    }
}
}

