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
			model.biomes.layers[0] = new Object();
			model.biomes.layers[0].functionName = "GenerateCube"
			model.biomes.layers[0].type = "AIR"
			model.biomes.layers[0].offset = model.grainSize
			
			model.biomes.layers[1] = new Object();
			model.biomes.layers[1].functionName = "GenerateLayer"
			model.biomes.layers[1].type = "STONE"
			model.biomes.layers[1].range = 90
			model.biomes.layers[1].offset = 45
			model.biomes.layers[1].optionalInt = 5
/*			
			model.biomes.layers[2] = new Object();
			model.biomes.layers[2].functionName = "GenerateLayer"
			model.biomes.layers[2].type = "GRAVEL"
			model.biomes.layers[2].range = 70
			model.biomes.layers[2].offset = 50
			model.biomes.layers[2].optionalInt = 5
			
			model.biomes.layers[3] = new Object();
			model.biomes.layers[3].functionName = "GenerateLayer"
			model.biomes.layers[3].type = "STONE"
			model.biomes.layers[3].range = 70
			model.biomes.layers[3].offset = 55
			model.biomes.layers[3].optionalInt = 5
			
			model.biomes.layers[4] = new Object();
			model.biomes.layers[4].functionName = "GenerateLayer"
			model.biomes.layers[4].type = "SAND"
			model.biomes.layers[4].range = 70
			model.biomes.layers[4].offset = 60
			model.biomes.layers[4].optionalInt = 7
			
			model.biomes.layers[5] = new Object();
			model.biomes.layers[5].functionName = "GenerateLayer"
			model.biomes.layers[5].type = "DIRT"
			model.biomes.layers[5].range = 90
			model.biomes.layers[5].offset = 70
			model.biomes.layers[5].optionalInt = 8

			model.biomes.layers[6] = new Object();
			model.biomes.layers[6].functionName = "GenerateWater"
			model.biomes.layers[6].type = "WATER"
			model.biomes.layers[6].range = 78
			model.biomes.layers[6].optionalInt = 8

			model.biomes.layers[7] = new Object();
			model.biomes.layers[7].functionName = "GenerateLayer"
			model.biomes.layers[7].type = "AIR"
			model.biomes.layers[7].range = 30
			model.biomes.layers[7].optionalInt = 5
			
			model.biomes.layers[8] = new Object();
			model.biomes.layers[8].functionName = "CarveOutsideSurface"
			model.biomes.layers[8].range = 100
			model.biomes.layers[8].offset = 40
			model.biomes.layers[8].optionalInt = 5
			
			model.biomes.layers[9] = new Object();
			model.biomes.layers[9].functionName = "GenerateGrassAndTrees"
	*/		
			return model;
		}
    }
}
