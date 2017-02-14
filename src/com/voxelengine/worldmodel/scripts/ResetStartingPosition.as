/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

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
