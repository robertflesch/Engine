/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.ModelInfoEvent;
	import com.voxelengine.events.OxelDataEvent;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.biomes.*;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.getTimer;
	import com.voxelengine.worldmodel.Region;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateLayer extends LandscapeTask 
	{		
		public function GenerateLayer( $guid:String, $layer:LayerInfo ):void {
			super( $guid, $layer, "GenerateLayer: " + (TypeInfo.typeInfo[$layer.type].name.toUpperCase()) );
			Log.out( "GenerateLayer: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
		}
		
		override public function start():void {
            super.start(); // AbstractTask will send event
			Log.out( "GenerateLayer.start: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
			// is it  ready?
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) );
		}
		
		private function modelInfoResult(e:ModelInfoEvent):void {
			Log.out( "GenerateLayer.modelInfoResult: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
			throw new Error( "REFACTOR with new oxel generation scheme");
			if ( e.modelGuid == _modelGuid ) {
				ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
				if ( e.vmi.oxelPersistence.oxelCount ) {
					var oxel:Oxel = e.vmi.oxelPersistence.oxel;
					if (null == oxel) {
						Log.out("GenerateLayer.modelInfoResult = no oxel found, waiting on OXEL_READY", Log.WARN);
						super.complete();
						return
					}
					processOxel(oxel)
				}
			}
		}
		
		private function processOxel( $oxel:Oxel ):void {
			var timer:int = getTimer();
			Log.out( "GenerateLayer.processOxel: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
			
			var smallestGrain:int = 4;
			var vm:VoxelModel = getVoxelModel();
			if ( vm ) {
				vm.complete = false;
				if ( vm.modelInfo.dbo.smallestGrain )
					smallestGrain = vm.modelInfo.dbo.smallestGrain
			}
			
			var masterMapSize:uint = Math.min( $oxel.size_in_world_coordinates(), 1024 );
			
			var octaves:int  = ( Math.random() * 144 ) % (Math.random() * 8);
			if ( 0 == octaves ) {
				octaves = 6;
				Log.out( "GenerateLayer - start - generating random number of Octaves: " + octaves );					
			} else 
				Log.out( "GenerateLayer - start - number of Octaves: " + octaves );					
			
			var masterHeightMap:Array = NoiseGenerator.generate_height_map( masterMapSize, octaves );
			//heightMap = generatePerlinNoise2DMap(voxels);
			Log.out( "GenerateLayer - start - generate_height_map took: " + (getTimer() - timer) );					
			timer = getTimer();
			
			// range should use up what ever percentage leftover from the offset
			var offsetInG0:int = _layer.offset/100 * GrainCursor.get_the_g0_size_for_grain($oxel.gc.grain);
			var remainingRange:int = $oxel.size_in_world_coordinates() - offsetInG0;
			var rangeInG0:int = remainingRange * _layer.range/100; 
			var normalizedMasterHeightMap:Array = NoiseGenerator.normalize_height_map_for_oxel( masterHeightMap
																							  , masterMapSize
																							  , rangeInG0
																							  , offsetInG0 );
					
			Log.out( "GenerateLayer - start - normalize_height_map_for_oxel took: " + (getTimer() - timer) );					
			timer = getTimer();
			// create a height map for each of the oxel levels
			var minHeightMapArray:Vector.<Array> = NoiseGenerator.get_height_mip_maps( normalizedMasterHeightMap, masterMapSize, NoiseGenerator.NOISE_MIN );
			var maxHeightMapArray:Vector.<Array> = NoiseGenerator.get_height_mip_maps( normalizedMasterHeightMap, masterMapSize, NoiseGenerator.NOISE_MAX );
			Log.out( "GenerateLayer - start - get_height_mip_maps took: " + (getTimer() - timer) );					
			timer = getTimer();

			// Array is only 10 in size, so if grain is larger then 10, we only calculate 10 levels down MAX.
			var arrayOffset:int = 0;
			if ( 10 < $oxel.gc.bound )
				arrayOffset = 10;
			else
				arrayOffset = $oxel.gc.bound;
			
			var minGrain:int = $oxel.gc.grain - _layer.optionalInt;
			if ( minGrain < smallestGrain ) 
				minGrain = smallestGrain;
			Log.out( "GenerateLayer - start - min Grain set to: " + minGrain );					
			
			var ignoreSolid:Boolean = false;
			if ( TypeInfo.AIR == _layer.type || TypeInfo.RED == _layer.type )
				ignoreSolid = true;
			/////////////////////////////////////////////////////////////////	
			// TODO Could I rewrite this as a chunk oriented vistor process?
			// But chunks are of variable size, 
			// could probably compensate for it, since they do point to a continuous peice of oxel data
			/////////////////////////////////////////////////////////////////
			$oxel.write_height_map( _modelGuid, _layer.type, minHeightMapArray, maxHeightMapArray, minGrain, arrayOffset, ignoreSolid );
			Log.out( "GenerateLayer - completed layer of type: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer() - timer) ); // + " in queue for: " + (timer - _startTime));
			
            super.complete(); // AbstractTask will send event
			
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}