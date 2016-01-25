/*==============================================================================
  Copyright 2011-2016 Robert Flesch
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
public class GrowTreesOn extends LandscapeTask 
{		
	public function GrowTreesOn( guid:String, layer:LayerInfo ):void {
		Log.out( "GrowTreesOn.created" );					
		super(guid, layer);
	}
	
	override public function start():void {
		super.start();
		var timer:int = getTimer();
		
		//Log.out( "GrowTreesOn.start - enter: ", Log.ERROR);					
		var vm:VoxelModel = getVoxelModel();
		if ( vm ) {
			if ( vm.modelInfo.data && vm.modelInfo.data.oxel ) {
				// This should be 1 - 100 range
				//var outOf:int = _layer.range;
				//vm.oxel.growTreesOn( _layer.type, outOf ? outOf : 2000 );
				// 100 is 100
				// 1 is 2000
				var oxel:Oxel = vm.modelInfo.data.oxel;
				var outOf:int = 81 + 1900 / _layer.range;
				oxel.growTreesOn( _modelGuid, _layer.type, outOf ? outOf : 1000 );
			}
			else
				Log.out( "GrowTreesOn.start - vm.modelInfo.data || vm.modelInfo.data.oxel not found for guid: " + _modelGuid, Log.WARN );
		}
		else
			Log.out( "GrowTreesOn.start - VM not found for guid: " + _modelGuid, Log.WARN );

		Log.out( "GrowTreesOn.start - took: " + (getTimer() - timer) + " in queue for: " + (timer - _startTime) );	
		
		super.complete();
	}
}
}