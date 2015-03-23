/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateSubSphere extends LandscapeTask 
	{		
		public function GenerateSubSphere( guid:String,layer:LayerInfo ):void {
			//Log.out( "GenerateSubSphere.construct of type: " + (Globals.Info[layer.type].name.toUpperCase()) );					
			super(guid, layer, "GenerateSubSphere: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function start():void
		{
			super.start() // AbstractTask will send event

			var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Solid Cube of any grain size
			//////////////////////////////////////////////////////////
			var vm:VoxelModel = getVoxelModel();
			if ( null == vm.oxel )
				vm.initialize_root_oxel( vm.instanceInfo.grainSize );
			var root_grain_size:uint = vm.oxel.gc.bound;
			var min_grain_size:int = vm.instanceInfo.grainSize;
			//var min_grain_size:int = root_grain_size - _layer.range;
			if ( 0 > min_grain_size || min_grain_size > root_grain_size || ( 8 < (root_grain_size - min_grain_size)) )
			{
				min_grain_size = Math.max( 0, root_grain_size - 4 );
				Log.out( "GenerateSubSphere.start - WARNING - Adjusting range: " + min_grain_size, Log.WARN );
			}
				
			var c:int = vm.oxel.size_in_world_coordinates() / 2;
			//vm.oxel.write_sphere( c, c, c, c - 1, _layer.type, min_grain_size );
			// sphere
//				vm.oxel.write_sphere( c, c, c, c, _layer.type, min_grain_size );
			// 3/4 sphere
//				vm.oxel.write_sphere( c, c/2, c, c, _layer.type, min_grain_size );
			// 1/2 sphere
			vm.oxel.write_sphere( _instanceGuid, c, c, c, c/2, _layer.type, min_grain_size );
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
			//Log.out( "GenerateSubSphere.start - completed layer of type: " + (Globals.Info[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer()-timer) + " in queue for: " + (timer-_startTime));
			super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}