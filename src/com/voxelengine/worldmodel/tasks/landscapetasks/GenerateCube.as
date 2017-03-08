/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.Log;
	import flash.utils.getTimer;
	import com.voxelengine.worldmodel.TypeInfo;
	
	public class GenerateCube extends LandscapeTask
	{	
		static public function script( $grain:int = 6, $type:int = 0 ):Object {
			if ( 0 == $type )
				$type = TypeInfo.SAND;
			var model:Object = {};
			model.name = "GenerateCube";
			model.grainSize = $grain;
			model.biomes = {};
			model.biomes.layers = new Vector.<Object>();
			model.biomes.layers[0] = {};
			model.biomes.layers[0].functionName = "GenerateCube";
			model.biomes.layers[0].type = TypeInfo.name( $type );
			
			return model;
		}
		
		public function GenerateCube( $guid:String, layer:LayerInfo ):void {
			super($guid, layer, "GenerateCube");
		}
		
		override public function start():void {
			var timer:int =  getTimer();
            super.start() // AbstractTask will send event

			Oxel.generateCube( _modelGuid, _layer );

            super.complete(); // AbstractTask will send event
			//Log.out( "GenerateCube.start guid: " + _modelGuid + " type: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) + " took: " + (getTimer() - timer), Log.WARN );
		}
	}
}
