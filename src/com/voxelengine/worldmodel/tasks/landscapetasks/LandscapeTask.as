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
	
	import com.voxelengine.worldmodel.models.types.VoxelModel;
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
		protected var _instanceGuid:String;
		protected var _layer:LayerInfo;
		protected var _startTime:int;
		static protected var _autoFlowState:Boolean;
		static protected var _taskCount:int;
		
		public static const TASK_TYPE:String = "ABSTRACT_LANDSCAPE_TASK";
        public static const TASK_PRIORITY:int = 1;
		
		public function LandscapeTask( guid:String, layer:LayerInfo, taskType:String = TASK_TYPE, taskPriority:int = TASK_PRIORITY ):void {
			_instanceGuid = guid;
			_layer = layer;
			_startTime = getTimer();
			// turn off autoflow during landscape, turn it back on when all are complete.
			if ( true == Globals.autoFlow ) {
				_autoFlowState = true;
				Globals.autoFlow = false;
			}
			_taskCount++;
			super(taskType, taskPriority);
		}
		
		override public function complete():void {
			_taskCount--;
			// turn off autoflow during landscape operations.
			if ( true == _autoFlowState && 0 == _taskCount )
				Globals.autoFlow = true;
			super.complete();	
		}

		
		protected function getVoxelModel():VoxelModel {

			var vm:VoxelModel;
			if ( _layer ) {
				var topMostParentGuid:String = _layer.optionalString;
				if ( "" != topMostParentGuid ) {
					vm = Globals.modelGet( topMostParentGuid );
					if ( vm )
						vm = vm.childModelFind( _instanceGuid );
					else 	
						Log.out( "LandscapeTask.getVoxelModel - FAILED voxel model for parent guid " + topMostParentGuid + "  data: " + _layer.data , Log.ERROR );
				}
				else
					vm = Globals.modelGet( _instanceGuid );
			}
			else
				vm = Globals.modelGet( _instanceGuid );
			
			return vm;	
		}
		
		protected function getVoxelInstance():VoxelModel {

			var vm:VoxelModel;
			if ( _layer ) {
				var topMostParentGuid:String = _layer.optionalString;
				if ( "" != topMostParentGuid ) {
					vm = Globals.modelGet( topMostParentGuid );
					if ( vm )
						vm = vm.childModelFind( _instanceGuid );
					else 	
						Log.out( "LandscapeTask.getVoxelModel - FAILED voxel model for parent guid " + topMostParentGuid + "  data: " + _layer.data , Log.ERROR );
				}
				else
					vm = Globals.modelGet( _instanceGuid );
			}
			else
				vm = Globals.modelGet( _instanceGuid );
			
			return vm;	
		}
	}
}