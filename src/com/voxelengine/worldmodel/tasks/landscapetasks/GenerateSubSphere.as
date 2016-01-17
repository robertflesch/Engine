/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.OxelPersistance;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateSubSphere extends LandscapeTask 
	{		
		static public function script():Object {
			var model:Object = new Object
			model.grainSize = 6
			model.name = "GenerateSubSphere"
			model.biomes = new Object();
			model.biomes.layers = new Vector.<Object>();
			model.biomes.layers[0] = new Object();
			model.biomes.layers[0].functionName = "GenerateSubSphere"
			model.biomes.layers[0].type = "SAND"
			model.biomes.layers[0].range = 3
			model.biomes.layers[0].offset = 7
			
			return model;
		}
			
		public function GenerateSubSphere( guid:String,layer:LayerInfo ):void {
			//Log.out( "GenerateSubSphere.construct of type: " + (Globals.Info[layer.type].name.toUpperCase()) );					
			super(guid, layer, "GenerateSubSphere: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
		
		override public function start():void
		{
			super.start() // AbstractTask will send event

			var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Sphere Cube of any grain size
			//////////////////////////////////////////////////////////
			const root_grain_size:int = _layer.offset;
			const baseLightLevel:int = 51;
			var oxel:Oxel = Oxel.initializeRoot( root_grain_size, baseLightLevel );
			//
			var min_grain_size:int = _layer.range;
			if ( 0 > min_grain_size || min_grain_size > (root_grain_size - 3) || ( 8 < (root_grain_size - min_grain_size)) )
			{
				min_grain_size = Math.max( 0, root_grain_size - 5 );
				Log.out( "GenerateSubSphere.start - WARNING - Adjusting range: " + min_grain_size, Log.WARN );
			}

			var c:int = oxel.size_in_world_coordinates() / 2;
			//vm.oxel.write_sphere( c, c, c, c - 1, _layer.type, min_grain_size );
			// sphere
//				vm.oxel.write_sphere( c, c, c, c, _layer.type, min_grain_size );
			// 3/4 sphere
//				vm.oxel.write_sphere( c, c/2, c, c, _layer.type, min_grain_size );
			// 1/2 sphere
			Log.out( "GenerateSubSphere.using params oxel.gc.bound: " + oxel.gc.bound + "  c: " + c + " min grain: " + min_grain_size, Log.WARN );
			//oxel.write_sphere( _instanceGuid, c, c, c, c, _layer.type, min_grain_size );
//			oxel.write_sphere( _instanceGuid, c, c/2, c, c, _layer.type, min_grain_size );
			oxel.write_sphere( _modelGuid, c, 0, c, c, _layer.type, min_grain_size );

			/* 
			// 8 spheres 
			var type:int = TypeInfo.GRASS;
			vm.write_sphere( c/2, c/2, c/2, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2, c/2, c/2 + c, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2, c/2 + c, c/2, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2, c/2 + c, c/2 + c, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2 + c, c/2, c/2, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2 + c, c/2, c/2 + c, c/2 - 1, type++, min_grain_size );
			vm.write_sphere( c/2 + c, c/2 + c, c/2, c/2 - 1, --type, min_grain_size );
			vm.write_sphere( c/2 + c, c/2 + c, c/2 + c, c/2 - 1, --type, min_grain_size );
			*/

			oxel.dirty = true;
			// CRITICAL STEP. when restoring the oxel, it expects to have faces, not dirty faces
			// So this step turns the dirty faces into real faces.
			// for multistep builds I will have to ponder this more.
//			oxel.facesBuildWater();
			oxel.facesBuild();
			
			var ba:ByteArray = OxelPersistance.toByteArray( oxel );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, 0, Globals.IVM_EXT, _modelGuid, null, ba ) );
			
			
			//Log.out( "GenerateSphere.start - completed layer of type: " + (Globals.Info[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer()-timer) + " in queue for: " + (timer-_startTime));
			super.complete() // AbstractTask will send event
		}
		
	}
}