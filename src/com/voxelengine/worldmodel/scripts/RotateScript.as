/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.worldmodel.scripts
{
/**
 * ...
 * @author Bob
 */
import com.voxelengine.Globals;
import com.voxelengine.GUI.actionBars.WindowShipControl;
import com.voxelengine.GUI.actionBars.WindowGunControl;
import com.voxelengine.GUI.WindowShipControlQuery;
import com.voxelengine.worldmodel.models.ModelTransform;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.events.TriggerEvent;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class RotateScript extends Script
{
    private var _rotationRate:Number = 1;
    public function RotateScript( $rotationRate:Number = 1 ) {
        _rotationRate = $rotationRate
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
        return {name: Script.getCurrentClassName(this), param: _rotationRate }
    }

}
}