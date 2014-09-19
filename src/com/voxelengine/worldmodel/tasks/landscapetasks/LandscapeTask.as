/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import flash.utils.getTimer;
	
	import com.developmentarc.core.tasks.tasks.AbstractTask;
	
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class LandscapeTask extends AbstractTask 
	{		
		protected var _guid:String;
		protected var _layer:LayerInfo;
		protected var _startTime:int;
		
		public static const TASK_TYPE:String = "ABSTRACT_LANDSCAPE_TASK";
        public static const TASK_PRIORITY:int = 1;
		
		public function LandscapeTask( guid:String, layer:LayerInfo, taskType:String = TASK_TYPE, taskPriority:int = TASK_PRIORITY ):void {
			_guid = guid;
			_layer = layer;
			_startTime = getTimer();
			
			super(taskType, taskPriority);
		}
		
		protected function getVoxelModel():VoxelModel {

			var vm:VoxelModel;
			var topMostParentGuid:String = _layer.optionalString;
			if ( "" != topMostParentGuid ) {
				vm = Globals.getModelInstance( topMostParentGuid );
				if ( vm )
					vm = vm.childModelFind( _guid );
				else 	
					Log.out( "LandscapeTask.getVoxelModel - FAILED voxel model for parent guid " + topMostParentGuid + "  data: " + _layer.data , Log.ERROR );
			}
			else
				vm = Globals.getModelInstance( _guid );
			
			return vm;	
		}
		
	}
}