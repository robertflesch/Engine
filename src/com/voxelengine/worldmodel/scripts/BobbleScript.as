/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.worldmodel.scripts
{

import flash.geom.Vector3D;

import com.voxelengine.Log;
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;


public class BobbleScript extends Script
{
    private var _defaultBobbleTime:Number = 5;
    private var _defaultBobbleDistance:Number = 100;
    private var _originalPos:Vector3D = new Vector3D();
    public function BobbleScript(  $params:Object ) {
        super($params);
        fromObject( $params )
    }

    override public function init():void {
        _originalPos = vm.instanceInfo.positionGet.clone();
        addBobble();
    }

    private function addBobble():void {
        TransformEvent.addListener( TransformEvent.ENDED, transformEnded );
        vm.instanceInfo.addTransform( 0, _defaultBobbleDistance, 0, _defaultBobbleTime, ModelTransform.POSITION_REPEATING, "BobbleScript" );
    }

    private function transformEnded( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformEnded );
        Log.out( "BobbleScript.scriptExpired")
    }

    private function restoreOriginal():void {
        // have to call this before I dispose of the handle to the VM
        if ( vm ) {
            vm.instanceInfo.removeNamedTransform(ModelTransform.POSITION_REPEATING, "BobbleScript");
            vm.instanceInfo.positionSet = _originalPos;
        }
    }

    override public function dispose():void {
        restoreOriginal();
        super.dispose();
    }

    override public function toObject():Object {
        return {name: getCurrentClassName( this ) , param: paramsObject() };
    }

    public function paramsObject():Object {
        return { defaultBobbleTime: _defaultBobbleTime, defaultBobbleDistance: _defaultBobbleDistance };
    }

    override public function fromObject( $params:Object):void {
        if ( $params ) {
            if ($params.defaultBobbleTime)
                _defaultBobbleTime = $params.defaultBobbleTime;
            if ($params.defaultBobbleDistance)
                _defaultBobbleDistance = $params.defaultBobbleDistance;

            if ( vm ) {
                restoreOriginal();
                addBobble();
            }
        }
    }

    override public function paramsString():String {
        return JSON.stringify( paramsObject() );
    }

}
}