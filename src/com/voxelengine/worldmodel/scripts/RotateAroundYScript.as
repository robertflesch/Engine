/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.scripts {

import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;

public class RotateAroundYScript extends Script
{
    public static const ROTATE_AROUND_Y_SCRIPT:String = "RotateAroundYScript";
    private var _rotationRate:Number = 1;
    public function RotateAroundYScript( $params:Object ) {
        super( $params );
        fromObject( $params );
    }

    override public function init():void {
        addRotation();
    }

    private function addRotation():void {
        TransformEvent.addListener( TransformEvent.ENDED, transformEnded );
        vm.instanceInfo.addTransform( 0, _rotationRate, 0, -1, ModelTransform.ROTATION_REPEATING, ROTATE_AROUND_Y_SCRIPT );
    }

    private function transformEnded( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformEnded );
    }

    private function reset():void {
        // have to call this before I dispose of the handle to the VM
        if ( vm )
            vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION_REPEATING, ROTATE_AROUND_Y_SCRIPT );
    }

    override public function dispose():void {
        vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION_REPEATING, ROTATE_AROUND_Y_SCRIPT );
        super.dispose();
    }

    override public function toObject():Object {
        return {name: Script.getCurrentClassName(this), param: { rotationRate: _rotationRate } };
    }

    override public function fromObject( $params:Object ):void {
        if ( $params ) {
            if ($params.rotationRate)
                _rotationRate = $params.rotationRate;

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