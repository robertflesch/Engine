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
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.*;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.OxelBad;
import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class CarveOutsideSurface extends LandscapeTask 
	{		
		public function CarveOutsideSurface( guid:String,layer:LayerInfo ):void {
			Log.out( "CarveOutsideSurface - created" );					
			super( guid, layer);
		}
		
		override public function start():void {
			super.start();
			var timer:int = getTimer();
			trace( "CarveOutsideSurface  - enter ", Log.ERROR );					
			var vm:VoxelModel = getVoxelModel();

			var masterHeightMap:Array;
			var masterMapSize:uint;

			var size:int = vm.modelInfo.oxelPersistence.oxel.size_in_world_coordinates();
			var oxel:Oxel = vm.modelInfo.oxelPersistence.oxel;
			masterMapSize = Math.min( size, 1024 );
			masterHeightMap = NoiseGenerator.generate_height_map( masterMapSize );
			trace( "CarveOutsideSurface - start - generate_height_map took: " + (getTimer() - timer) );		
			timer = getTimer();

			// range should use up what ever percentage leftover from the offset
			var offsetInG0:int = _layer.offset * GrainCursor.get_the_g0_size_for_grain(oxel.gc.grain) / 100;
			var remainingRange:int = oxel.size_in_world_coordinates() - offsetInG0;
			var rangeInG0:int = remainingRange * (_layer.range/100);
			masterHeightMap = NoiseGenerator.normalize_height_map_for_oxel( masterHeightMap
																		  , masterMapSize
																		  , rangeInG0
																		  , offsetInG0 );
			
			
			var minGrain:int = oxel.gc.grain - _layer.optionalInt;
			var minGrainInG0:int = GrainCursor.get_the_g0_size_for_grain( minGrain );
			
			var height:int = 0;
			var rradius:int = size;
			var center:int = size/2;
			var endX:int = size/minGrainInG0;
			var endY:int = size/minGrainInG0;
			var endZ:int = size/minGrainInG0;
			var offset:int = 0;
			var bound:int = oxel.gc.bound;
			var to:Oxel = OxelBad.INVALID_OXEL;
			var gct:GrainCursor = GrainCursorPool.poolGet( bound );
			gct.become_ancestor( minGrain );
			var mapIncrement:int = minGrainInG0;
			if ( masterHeightMap.length < (minGrainInG0 * endX) )
			{
				mapIncrement = masterHeightMap.length / endX;
			}
			//for ( var y:int = endY; y >= 0; y-- ) {
			trace( "CarveOutsideSurface - start - applying height map to outside of oxel - took: " + (getTimer() - timer) );		
			timer = getTimer();
			
			for ( var y:int = endY - 1; y >= 0; y-- ) {				
				for ( var z:int = 0; z < endZ; z++) {
					for ( var x:int = 0; x < endX; x++) {
						
						height = masterHeightMap[x * mapIncrement + offset][z * mapIncrement + offset];
						var heightAdjustedMaxRadius:Number = 0;
						// this line decides how much of a cone effect there is when applying the height map to outside of oxel
						heightAdjustedMaxRadius = (-4 * minGrainInG0 ) + (y * minGrainInG0/2);

						heightAdjustedMaxRadius += height;
						//heightAdjustedMaxRadius *= 0.55;
						heightAdjustedMaxRadius *= 0.50;
						
						var voxelDistToCenter:Number = Math.sqrt( (center - x * minGrainInG0 ) * (center - x* minGrainInG0) + (center - z* minGrainInG0) * (center - z* minGrainInG0) );
						if ( voxelDistToCenter > heightAdjustedMaxRadius )
						{
							GrainCursor.roundToInt( x, y, z, gct );
							to = oxel.childFind( gct );
							if ( OxelBad.INVALID_OXEL != to )
							{
								to.change( _modelGuid, gct, TypeInfo.AIR );
								//to.writeFromHeightMap( gct, TypeInfo.AIR );
							}
						}
					}
					if ( offset < (mapIncrement - 1) )
						offset++;
					else
						offset = 0;
				}
			}
			GrainCursorPool.poolDispose( gct );
			
			//trace( "CarveOutsideSurface - took: " + (getTimer() - timer) ); // + " in queue for: " + (timer - _startTime) );					
			//Log.out( "CarveOutsideSurface - merging: ");
			//var stillNodes:Boolean = true;
			//while ( stillNodes )
			//{
				//timer = getTimer();
				//Oxel.nodes = 0;
				//oxel.mergeRecursive();
				//if ( 50 > Oxel.nodes )
					//stillNodes = false;
				//Log.out( "CarveOutsideSurface - merging recovered: " + Oxel.nodes + " took: " + (getTimer() - timer) );
			//}
			
			super.complete();
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}