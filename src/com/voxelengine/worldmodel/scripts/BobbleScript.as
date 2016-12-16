/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.worldmodel.scripts
{
/**
 * ...
 * @author Bob
 */

import com.voxelengine.Log;
import com.voxelengine.events.ScriptEvent;
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;

import flash.geom.Vector3D;

public class BobbleScript extends Script
{
    private var _defaultBobbleRate:Number = 15;
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
        TransformEvent.addListener( TransformEvent.ENDED, transformExpired );
        vm.instanceInfo.addTransform( 0, _defaultBobbleDistance, 0, _defaultBobbleRate, ModelTransform.POSITION, "BobbleScript" );
    }

    private function transformExpired( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformExpired );
        Log.out( "BobbleScript.scriptExpired")
    }

    override public function dispose():void {
        // have to call this before I dispose of the handle to the VM
        vm.instanceInfo.removeNamedTransform( ModelTransform.POSITION, "BobbleScript" );
        vm.instanceInfo.positionSet = _originalPos;
        super.dispose();
    }

    override public function toObject():Object {
        return {name: super.toString() , param: { defaultBobbleRate: _defaultBobbleRate, defaultBobbleDistance: _defaultBobbleDistance } };
    }

    override public function fromObject( $params:Object):void {
        if ( $params ) {
            if ($params.defaultBobbleRate)
                _defaultBobbleRate = $params.defaultBobbleRate;
            if ($params.defaultBobbleDistance)
                _defaultBobbleDistance = $params.defaultBobbleDistance;
        }
    }

    override public function toString():String {
        return  '{ "defaultBobbleRate": ' + _defaultBobbleRate +
                ', "defaultBobbleDistance": ' + _defaultBobbleDistance + ' }';
    }

}
}