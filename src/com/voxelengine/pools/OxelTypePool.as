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
import com.voxelengine.worldmodel.oxel.Oxel

public final class OxelTypePool
{
    private var _currentPoolSize:uint;
    private var _growthValue:uint;
    private var _counter:uint;
    private var _pool:Vector.<Oxel>;
    private var _oxelClass:Class;

    public function remaining():uint { return _counter; }
    public function totalUsed():uint { return _currentPoolSize - _counter; }
    public function total():uint { return _currentPoolSize; }

    public function OxelTypePool( $type:uint, $initialPoolSize:uint, $growthValue:uint ):void {
        var oxelClass:Class = Oxel.getClassFromType( $type );
        _oxelClass = oxelClass;
        _currentPoolSize = $initialPoolSize;
        _growthValue = $growthValue;
//        _counter = $initialPoolSize;

//        var i:uint = _counter;
//        _pool = new Vector.<Oxel>(_counter);
//        _counter = 0;
//        _pool = new Vector.<Oxel>(_currentPoolSize);
//
//        while( --i > -1 )
//            _pool[i] = new _oxelClass();
        grow( $initialPoolSize );
    }

    private function grow( $growthValue:int ):void {
        Log.out( "OxelTypePool.poolGet - Allocating more Oxel: " + _currentPoolSize );
        var timer:int = getTimer();
        _currentPoolSize += $growthValue;
        _pool = null;
        _pool = new Vector.<Oxel>(_currentPoolSize);
        for ( var newIndex:int = 0; newIndex < $growthValue; newIndex++ )
            _pool[newIndex] = new _oxelClass();

        _counter = newIndex - 1;
        Log.out( "OxelTypePool.poolGet - Done allocating more Oxel: " + _currentPoolSize  + " took: " + (getTimer() - timer) );
    }

    public function poolGet():Oxel {
        if ( _counter > 0 )
            return _pool[--_counter];

        grow( _growthValue );

        return poolGet();
    }

    public function poolDispose( $disposedOxel:Oxel):void {
        _pool[_counter++] = $disposedOxel;
    }
}
}
