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
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.TypeInfo;

// This class generates a cube, and starts a face and quad build on it
// DEPRECATED, use GenerateOxel
public class GenerateCube extends LandscapeTask {
	static public function script($grain:int = 6, $type:int = 0):Object {
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
		nbiomes.layers[0].offset = $grain;
		model.biomes = nbiomes;

		return model;
	}

	static public function addTask($guid:String, layer:LayerInfo, $taskPriority:int = 5 ):void {
		var genCube:GenerateCube = new GenerateCube($guid, layer, $taskPriority);
		Globals.g_landscapeTaskController.addTask(genCube);
	}

	// HAS to be public, but should NEVER be called
	public function GenerateCube($guid:String, layer:LayerInfo, $taskPriority:int):void {
		super($guid, layer, "GenerateCube", $taskPriority);
	}

	override public function start():void {
		super.start();
		Log.out("GenerateCube.start");
		// This generates a GENERATION_SUCCESS, which is picked up by the OxelPersistenceCache
		// which then starts the build process
		Oxel.generateCube(_modelGuid, _layer);
	}
}
}
