/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.worldmodel.scripts
{
/**
 * ...
 * @author Bob
 */
import com.voxelengine.worldmodel.models.ModelTransform;

public class RotateScript extends Script
{
    private var _rotationRate:Number = 1;
    public function RotateScript( $params:Object ) {
        super( $params );
        if ( $params && $params.rotationRate )
            _rotationRate = $params.rotationRate;
    }

    override public function init():void {
        //addTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ):void {
        vm.instanceInfo.addTransform( 0, _rotationRate, 0, -1, ModelTransform.ROTATION, "RotateScript" );
    }

    override public function dispose():void {
        vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION, "RotateScript" );
        super.dispose();
    }

    override public function toObject():Object {
        return {name: Script.getCurrentClassName(this), param: { rotationRate: _rotationRate } };
    }

    override public function fromObject( $obj:Object):void {
        if ( $obj && $obj.rotationRate )
            _rotationRate = $obj.rotationRate;
    }

}
}