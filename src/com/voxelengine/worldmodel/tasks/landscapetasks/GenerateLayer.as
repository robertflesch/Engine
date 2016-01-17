/*==============================================================================
  Copyright 2011-2013 Robert Flesch
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
		public function GenerateLayer( $guid:String, layer:LayerInfo ):void {
			Log.out( "GenerateLayer of type: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );					
			super( $guid, layer, "GenerateLayer: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function start():void {
            super.start() // AbstractTask will send event
			// is it  ready?
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) );
		}
		
		private function oxelDataRetrieved(e:OxelDataEvent):void {
			if ( e.modelGuid == _modelGuid ) {
				OxelDataEvent.removeListener( OxelDataEvent.OXEL_READY, oxelDataRetrieved )
				var oxel:Oxel = e.oxelData.oxel
				processOxel( oxel )
			}
		}
		
		private function modelInfoResult(e:ModelInfoEvent):void {
			
			if ( e.modelGuid == _modelGuid ) {
				if ( !e.vmi || !e.vmi.data || !e.vmi.data.oxel ) {
					ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
					OxelDataEvent.addListener( OxelDataEvent.OXEL_READY, oxelDataRetrieved );		
					Log.out( "GenerateLayer.modelInfoResult = no oxel found, waiting on OXEL_READY", Log.ERROR )
					// error handling???
					// what if it never loads?
					return
				}
				var oxel:Oxel = e.vmi.data.oxel
				processOxel( oxel )
			}
		}
		
		private function processOxel( $oxel:Oxel ):void {
			var timer:int = getTimer();
			
			//Globals.g_seed = 0;
			const root_grain_size:int = _layer.offset;
			const baseLightLevel:int = 51;
			var masterMapSize:uint = Math.min( $oxel.size_in_world_coordinates(), 1024 );
			
			var octaves:int  = ( Math.random() * 144 ) % (Math.random() * 12);
			if ( 0 == octaves )
				octaves = 6;
			Log.out( "GenerateLayer - start - generating random number of octives Octaves: " + octaves );					
			
			var masterHeightMap:Array = NoiseGenerator.generate_height_map( masterMapSize, octaves );
			//heightMap = generatePerlinNoise2DMap(voxels);
			Log.out( "GenerateLayer - start - generate_height_map took: " + (getTimer() - timer) );					
			timer = getTimer();
			
            // same thing
			//var t:int = oxel.size_in_world_coordinates();
			//var t2:int = GrainCursor.get_the_g0_size_for_grain(oxel.gc.grain);
			
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
			{
				arrayOffset = 10;
			}
			else
				arrayOffset = $oxel.gc.bound;
			
			var minGrain:int = $oxel.gc.grain - _layer.optionalInt;
			if ( 0 > minGrain ) minGrain = 0;
			
			var ignoreSolid:Boolean = false;
			if ( TypeInfo.AIR == _layer.type || TypeInfo.RED == _layer.type )
				ignoreSolid = true;
			$oxel.write_height_map( _modelGuid, _layer.type, minHeightMapArray, maxHeightMapArray, minGrain, arrayOffset, ignoreSolid );
			Log.out( "GenerateLayer - completed layer of type: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer() - timer) ); // + " in queue for: " + (timer - _startTime));
			//timer = getTimer();
			//Log.out( "GenerateLayer - merging: ");
			//oxel.mergeRecursive();
			//Oxel.nodes = 0;
			//oxel.mergeRecursive();
			//Log.out( "GenerateLayer - merging recovered: " + Oxel.nodes + " took: " + (getTimer() - timer), Log.ERROR );
			//timer = getTimer();
			//Oxel.nodes = 0;
			//oxel.mergeRecursive();
			//Log.out( "GenerateLayer - merging 2 recovered: " + Oxel.nodes + " took: " + (getTimer() - timer), Log.ERROR );
			
            super.complete() // AbstractTask will send event
			
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}