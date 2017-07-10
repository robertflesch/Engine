/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.TypeInfo;

import flash.utils.ByteArray;
//import flash.utils.getTimer;
	
	public class GenerateSphere extends LandscapeTask
	{		
		static public function script($grain:int = 6, $type:int = 0, $lockLight:Boolean = false ):Object {
			if (0 == $type)
				$type = TypeInfo.SAND;
			var model:Object = {};
			model.name = "GenerateSphere";
			model.grainSize = $grain;
			model.lockLight = $lockLight;
			var nBiomes:Object = {};
			nBiomes.layers = new Vector.<Object>();
			nBiomes.layers[0] = {};
			nBiomes.layers[0].functionName = "GenerateSphere";
			nBiomes.layers[0].type = $type;
			nBiomes.layers[0].range = 3;
			nBiomes.layers[0].offset = 7;
			model.biomes = nBiomes;

			return model;
		}

		static public function addTask($guid:String, layer:LayerInfo, $taskPriority:int = 5 ):void {
			var genCube:GenerateSphere = new GenerateSphere($guid, layer, $taskPriority);
			Globals.taskController.addTask(genCube);
		}

		public function GenerateSphere( guid:String, layer:LayerInfo, $taskPriority:int ):void {
			//Log.out( "GenerateSphere.construct of type: " + (Globals.Info[layer.type].name.toUpperCase()) );					
			super(guid, layer, "GenerateSphere: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()), $taskPriority );
		}
		
		override public function start():void {
			super.start(); // AbstractTask will send event
			//var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Sphere Cube of any grain size
			//////////////////////////////////////////////////////////
			const rootGrain:int = _layer.offset;
			var oxel:Oxel = Oxel.initializeRoot( rootGrain );
			//
			var min_grain_size:int = _layer.range;
			if ( 0 > min_grain_size || min_grain_size > (rootGrain - 3) || ( 8 < (rootGrain - min_grain_size)) )
			{
				min_grain_size = Math.max( 0, rootGrain - 5 );
				Log.out( "GenerateSphere.start - WARNING - Adjusting range: " + min_grain_size, Log.WARN );
			}

			var c:int = oxel.size_in_world_coordinates() / 2;

			Log.out( "GenerateSphere.using params oxel.gc.bound: " + oxel.gc.bound + "  c: " + c + " min grain: " + min_grain_size, Log.WARN );
			oxel.write_sphere( _modelGuid, c, c, c, c, _layer.type, min_grain_size );
			//////////////////
			oxel.dirty = true;
			// CRITICAL STEP. oxels are expected to have faces, not dirty faces
			// So this step turns the dirty faces into real faces.
			// for multistep island builds I will have to ponder this more.
			// TODO Ahhhh, you have to build faces HERE AND NOW
			// Since the toByteArray does NOT save dirty bits!!!!
			oxel.facesBuild();
			var ba:ByteArray = oxel.toByteArray();
//			Log.out( "GenerateCube finished object: " + Hex.fromArray( ba, true ) );
//			Log.out( "GenerateCube finished compressed object: " + Hex.fromArray( ba, true ) );
			//Log.out( "GenerateCube finished modelGuid: " + _modelGuid );

			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.GENERATE_SUCCEED, 0, Globals.IVM_EXT, _modelGuid, null, ba, null, rootGrain.toString() ) );
			super.complete();
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}