/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.scripts
{

import com.voxelengine.events.ScriptEvent;

import flash.geom.Vector3D;

import com.voxelengine.Log;
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;


public class BobbleScript extends Script
{
    public static const BOBBLE_SCRIPT:String = "BobbleScript";
    private var _defaultBobbleTime:Number = 30;
    private var _defaultBobbleDistance:Number = 100;
    private var _originalPos:Vector3D = new Vector3D();
    public function BobbleScript(  $params:Object ) {
        super($params);
        fromObject( $params )
    }

    override public function init( $instanceGuid:String ):void {
        super.init( $instanceGuid );
        _originalPos = vm.instanceInfo.positionGet.clone();
        addBobble();
    }

    private function addBobble():void {
        TransformEvent.addListener( TransformEvent.ENDED, transformEnded );
        vm.instanceInfo.addTransform( 0, _defaultBobbleDistance, 0, _defaultBobbleTime, ModelTransform.POSITION_REPEATING, BOBBLE_SCRIPT );
    }

    private function transformEnded( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformEnded );
    }

    private function reset():void {
        // have to call this before I dispose of the handle to the VM
        if ( vm ) {
            vm.instanceInfo.removeNamedTransform( ModelTransform.POSITION_REPEATING, BOBBLE_SCRIPT );
            vm.instanceInfo.positionSet = _originalPos;
        }
    }

    override public function dispose():void {
        reset();
        ScriptEvent.create( ScriptEvent.SCRIPT_EXPIRED, vm.instanceInfo.instanceGuid, BOBBLE_SCRIPT );
        super.dispose();
    }

    override protected function paramsObject():Object {
        return { defaultBobbleTime: _defaultBobbleTime, defaultBobbleDistance: _defaultBobbleDistance };
    }

    override public function fromObject( $params:Object):void {
        if ( $params ) {
            if ($params.defaultBobbleTime)
                _defaultBobbleTime = $params.defaultBobbleTime;
            if ($params.defaultBobbleDistance)
                _defaultBobbleDistance = $params.defaultBobbleDistance;

            if ( vm ) {
                reset();
                addBobble();
            }
        }
    }

    override public function paramsString():String {
        return JSON.stringify( paramsObject() );
    }

}
}