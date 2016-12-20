/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.worldmodel.scripts
{
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;

import flash.geom.Vector3D;

public class RotateScript extends Script
{
    public static const ROTATE_SCRIPT:String = "RotateScript";
    private var _rotationRate:Vector3D = new Vector3D();
    private var _rotationTime:int = -1;
    public function RotateScript( $params:Object ) {
        super( $params );
        fromObject( $params );
    }

    override public function init():void {
        addRotation();
    }

    private function addRotation():void {
        TransformEvent.addListener( TransformEvent.ENDED, transformEnded );
        vm.instanceInfo.addTransform( _rotationRate.x, _rotationRate.y, _rotationRate.z, _rotationTime, ModelTransform.ROTATION_REPEATING, ROTATE_SCRIPT );
    }

    private function transformEnded( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformEnded );
    }

    private function reset():void {
        // have to call this before I dispose of the handle to the VM
        if ( vm ) {
            vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION_REPEATING, ROTATE_SCRIPT );
        }
    }

    override public function dispose():void {
        vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION_REPEATING, ROTATE_SCRIPT );
        super.dispose();
    }

    override public function toObject():Object {
        return {name: Script.getCurrentClassName(this), param: { rotationRate: _rotationRate, rotationTime: _rotationTime } };
    }

    override public function fromObject( $params:Object ):void {
        if ( $params ) {
            if ($params.rotationRate) {
                _rotationRate.x = $params.rotationRate.x;
                _rotationRate.y = $params.rotationRate.y;
                _rotationRate.z = $params.rotationRate.z;
            }
            if ($params.rotationTime)
                _rotationTime = $params.rotationTime;

            if ( vm ) {
                reset();
                addRotation();
            }
        }
    }

    override protected function paramsObject():Object {
        return { rotationRate: _rotationRate };
    }
}
}