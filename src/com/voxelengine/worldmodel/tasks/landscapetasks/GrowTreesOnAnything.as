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
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GrowTreesOnAnything extends LandscapeTask 
	{		
		public function GrowTreesOnAnything( guid:String, layer:LayerInfo ):void {
			Log.out( "GrowTreesOnAnything.created", Log.WARN );					
			super(guid, layer);
		}
		
		override public function start():void {
			super.start();
			var timer:int = getTimer();

			Log.out( "GrowTreesOnAnything.start - enter: ");
			var vm:VoxelModel = getVoxelModel();
			if ( vm )
			{
				var outOf:int = _layer.range;
				vm.modelInfo.oxelPersistence.oxel.growTreesOnAnything( _modelGuid, outOf ? outOf : 2000 );
			}
			else
				Log.out( "GrowTreesOnAnything.start - VM not found for guid: " + _modelGuid );
			Log.out( "GrowTreesOnAnything.start - complete & trees - took: " + (getTimer() - timer) + " in queue for: " + (timer - _startTime) );	
			
			super.complete();
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}