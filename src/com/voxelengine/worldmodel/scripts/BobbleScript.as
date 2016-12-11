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

public class BobbleScript extends Script
{
    public function BobbleScript() {
    }

    override public function init():void {
        //addTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ):void {
        vm.instanceInfo.addTransform( 0, 1, 0, 5, ModelTransform.POSITION_REPEATING, "BobbleScript" );
    }

    override public function dispose():void {
        // have to call this before I dispose of the handle to the VM
        vm.instanceInfo.removeNamedTransform( ModelTransform.POSITION_REPEATING, "BobbleScript" );
        super.dispose();
    }

}

}