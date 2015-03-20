/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.tests
{
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.*;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.display.BitmapData;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class TestSphere extends LandscapeTask 
	{		
		public function TestSphere( guid:String,layer:LayerInfo ):void {
			trace( "TestSphere.construct of type: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );					
			super(guid, layer, "TestSphere: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function start():void
		{
			super.start() // AbstractTask will send event

			var timer:int = getTimer();
			
			var vm:VoxelModel = Globals.modelGet( _guid );
			if ( vm )
			{
				var root_grain_size:uint = vm.oxel.gc.bound
				var min_grain_size:int = root_grain_size - _layer.range;
				if ( 0 > min_grain_size || min_grain_size >= (root_grain_size - 2) || ( 8 < (root_grain_size - min_grain_size)) )
				{
					min_grain_size = Math.max( 0, root_grain_size - 6 );
					trace( "TestSphere.start - WARNING - Adjusting range: " + min_grain_size );
				}
				
				var c:int = vm.oxel.size_in_world_coordinates() / 2;
				// 1 large spheres 
				//vm.oxel.write_sphere( c, c, c, c - 1, _layer.type, min_grain_size );
				vm.oxel.write_sphere( _guid, c, c/2, c, c - 1, _layer.type, min_grain_size );
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
			}
			else
			{
				throw new Error("Didnt find model for: " + _guid );
			}

			trace( "TestSphere.start - completed layer of type: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer()-timer) + " in queue for: " + (timer-_startTime));
			super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}