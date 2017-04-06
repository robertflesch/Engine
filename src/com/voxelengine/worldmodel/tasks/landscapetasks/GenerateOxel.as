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
public class GenerateOxel extends LandscapeTask {
    static public function cubeScript($grain:int = 6, $type:int = 0):Object {
        if (0 == $type)
            $type = TypeInfo.SAND;
        var model:Object = {};
        model.name = "GenerateCube";
        model.grainSize = $grain;

        var nbiomes:Object = {};
        nbiomes.layers = new Vector.<Object>();
        nbiomes.layers[0] = {};
        nbiomes.layers[0].functionName = "GenerateCube";
        nbiomes.layers[0].type = $type;
        model.biomes = nbiomes;

        return model;
    }

    static public function sphereScript($grain:int = 6, $type:int = 0):Object {
        if (0 == $type)
            $type = TypeInfo.SAND;
        var model:Object = {};
        model.name = "GenerateSphere";
        model.grainSize = $grain;
        model.biomes = {};
        model.biomes.layers = new Vector.<Object>();
        model.biomes.layers[0] = {};
        model.biomes.layers[0].functionName = "GenerateSphere";
        model.biomes.layers[0].type = $type;
        model.biomes.layers[0].range = 3;
        model.biomes.layers[0].offset = 7;

        return model;
    }


    static public function addTask($guid:String, layer:LayerInfo, $taskPriority:int = 5 ):void {
        var gen:GenerateOxel = new GenerateOxel($guid, layer, $taskPriority);
        Globals.g_landscapeTaskController.addTask(gen);
    }

    // HAS to be public, but should NEVER be called
    public function GenerateOxel($guid:String, layer:LayerInfo, $taskPriority:int):void {
        super($guid, layer, "GenerateOxel", $taskPriority);
    }

    override public function start():void {
        super.start();
        Log.out("GenerateOxel.start - FIX SO ANY FUNCTION CAN WORK", Log.WARN );
        Oxel.generateCube( _modelGuid, _layer );
        super.complete();
    }
}
}
