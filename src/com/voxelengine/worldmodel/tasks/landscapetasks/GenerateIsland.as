/*==============================================================================
  Copyright 2011-2016 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateIsland 
	{	
		static public function script():Object {
			var model:Object = new Object
			model.grainSize = 12
			model.name = "GenerateIsland"
			model.biomes = new Object();
			model.biomes.layers = new Vector.<Object>();
			var i:int
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateCube"
			model.biomes.layers[i].type = "AIR"
			model.biomes.layers[i].offset = model.grainSize
			i++
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "STONE"
			model.biomes.layers[i].range = 90
			model.biomes.layers[i].offset = 45
			model.biomes.layers[i].optionalInt = 5
			i++
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "GRAVEL"
			model.biomes.layers[i].range = 80
			model.biomes.layers[i].offset = 52
			model.biomes.layers[i].optionalInt = 5
			i++
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "STONE"
			model.biomes.layers[i].range = 70
			model.biomes.layers[i].offset = 55
			model.biomes.layers[i].optionalInt = 6
			i++
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "SAND"
			model.biomes.layers[i].range = 70
			model.biomes.layers[i].offset = 60
			model.biomes.layers[i].optionalInt = 6
			i++
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "DIRT"
			model.biomes.layers[i].range = 90
			model.biomes.layers[i].offset = 70
			model.biomes.layers[i].optionalInt = 8
			i++
			/*

			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateWater"
			model.biomes.layers[i].type = "WATER"
			model.biomes.layers[i].range = 78
			model.biomes.layers[i].optionalInt = 8

			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateLayer"
			model.biomes.layers[i].type = "AIR"
			model.biomes.layers[i].range = 30
			model.biomes.layers[i].optionalInt = 5
			
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "CarveOutsideSurface"
			model.biomes.layers[i].range = 100
			model.biomes.layers[i].offset = 40
			model.biomes.layers[i].optionalInt = 5
			
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "GenerateGrassAndTrees"
	*/		
			model.biomes.layers[i] = new Object();
			model.biomes.layers[i].functionName = "MergeLayer"
			
			return model;
		}
    }
}
