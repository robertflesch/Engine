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
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.biomes.*;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.display.BitmapData;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class CarveOutsideVolcano extends LandscapeTask 
	{		
		public function CarveOutsideVolcano( guid:String, layer:LayerInfo ):void {
			Log.out( "CarveOutsideVolcano of type: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );					
			super( guid, layer, "CarveOutsideVolcano: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function start():void {
            super.start() // AbstractTask will send event
			
			/*
			 * Note I dont know that this is using the layer info correct or uniformly
			 * 
			 */
			var timer:int = getTimer();
			
			//Globals.g_seed = 0;
			
			var vm:VoxelModel = getVoxelModel();
			var oxel:Oxel = vm.modelInfo.oxelPersistence.oxel;
			var masterMapSize:uint = Math.min( oxel.size_in_world_coordinates(), 1024 );
			
			//var octaves:int  = ( Math.random() * 144 ) % (Math.random() * 12);
			var octaves:int;
			if ( 0 == octaves )
				octaves = 6;
			Log.out( "CarveOutsideVolcano - start - generating random number of octives Octaves: " + octaves );					
			
			var masterHeightMap:Array = NoiseGenerator.generate_height_map( masterMapSize, octaves );
			//heightMap = generatePerlinNoise2DMap(voxels);
			Log.out( "CarveOutsideVolcano - start - generate_height_map took: " + (getTimer() - timer) );					
			timer = getTimer();
			
			// range should use up what ever percentage leftover from the offset
			var offsetInG0:int = _layer.offset/100 * GrainCursor.get_the_g0_size_for_grain(oxel.gc.grain);
			var remainingRange:int = oxel.size_in_world_coordinates() - offsetInG0;
			var rangeInG0:int = remainingRange * _layer.range/100; 
			var normalizedMasterHeightMap:Array = NoiseGenerator.normalize_height_map_for_oxel( masterHeightMap
																							  , masterMapSize
																							  , rangeInG0
																							  , offsetInG0 );

			var volcanoRadius:Number = masterMapSize / 2 * 0.4;
			var highestPoint:Number = 0;
			for ( var x:int = 0; x < masterMapSize; x++ )
			{
				for ( var y:int = 0; y < masterMapSize; y++ )
				{
					var dx:int = masterMapSize/2 - x;
					var dy:int = masterMapSize/2 - y;
					
					var distanceFromCenter:Number = Math.sqrt( dx * dx + dy * dy );
					
					if ( distanceFromCenter < volcanoRadius )
					{
						var offsetAmount:Number = (remainingRange * (volcanoRadius - distanceFromCenter) / volcanoRadius);
						var angle:Number = dy / distanceFromCenter;
						var sin:Number = Math.sin( dy / distanceFromCenter );
						var angleOffsetAmount:Number = offsetAmount/ 5 + offsetAmount / 2 * sin;
						offsetAmount -= Math.abs( angleOffsetAmount );
						
						normalizedMasterHeightMap[x][y] = normalizedMasterHeightMap[x][y] + offsetAmount;
						if ( highestPoint < normalizedMasterHeightMap[x][y] )
							highestPoint = normalizedMasterHeightMap[x][y];
					}
				}
			}
			Log.out( "CarveOutsideVolcano.start - highest point: " + highestPoint + "  out of : " + oxel.size_in_world_coordinates() );					
			
																							  
			Log.out( "CarveOutsideVolcano - start - normalize_height_map_for_oxel took: " + (getTimer() - timer) );					
			timer = getTimer();
			// create a height map for each of the oxel levels
			var minHeightMapArray:Vector.<Array> = NoiseGenerator.get_height_mip_maps( normalizedMasterHeightMap, masterMapSize, NoiseGenerator.NOISE_MIN );
			var maxHeightMapArray:Vector.<Array> = NoiseGenerator.get_height_mip_maps( normalizedMasterHeightMap, masterMapSize, NoiseGenerator.NOISE_MAX );
			Log.out( "CarveOutsideVolcano - start - get_height_mip_maps took: " + (getTimer() - timer) );					
			timer = getTimer();

			// Array is only 10 in size, so if grain is larger then 10, we only calculate 10 levels down MAX.
			var arrayOffset:int = 0;
			if ( 10 < oxel.gc.bound )
				arrayOffset = 10;
			else
				arrayOffset = oxel.gc.bound;
			
			var minGrain:int = oxel.gc.grain - _layer.optionalInt;
			if ( 0 > minGrain ) 
				minGrain = 0;
			
			var ignoreSolid:Boolean = false;
			if ( TypeInfo.AIR == _layer.type || TypeInfo.RED == _layer.type )
				ignoreSolid = true;
			oxel.write_height_map( _modelGuid, _layer.type, minHeightMapArray, maxHeightMapArray, minGrain, arrayOffset, ignoreSolid );
			Log.out( "CarveOutsideVolcano - completed layer of type: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer() - timer) ); // + " in queue for: " + (timer - _startTime));
			
            super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}