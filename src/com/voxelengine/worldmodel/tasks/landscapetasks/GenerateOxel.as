/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.tasks.landscapetasks
{
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;
import com.voxelengine.worldmodel.TypeInfo;

// This class generates a cube, and starts a face and quad build on it
public class GenerateOxel {
    public function GenerateOxel() {

    }

    static public function resolveGenerationType( $functionName:String ):Class {
        if ( "GenerateCube" == $functionName )
            return GenerateCube;
        else if ( "GenerateSphere" == $functionName )
            return GenerateSphere;
        else if ( "GenerateTree" == $functionName )
            return GenerateTree;
        throw new Error( "Unknown generation type");
        return GenerateCube;
    }
}
}
