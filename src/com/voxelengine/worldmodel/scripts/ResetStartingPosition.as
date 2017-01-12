/**
 * Created by dev on 1/9/2017.
 */
package com.voxelengine.worldmodel.scripts {

public class ResetStartingPosition extends Script
{
    public static const RESET_STARTING_POSITION:String = "ResetStartingPosition";
    public function ResetStartingPosition(   $params:Object  ) {
        super($params);
    }
    override public function init():void {
        vm.instanceInfo.useOrigPosition = true;
    }
}
}
