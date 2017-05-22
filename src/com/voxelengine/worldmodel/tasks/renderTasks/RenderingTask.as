/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.renderTasks
{
import com.voxelengine.Log;

import flash.utils.getTimer
	
	import com.developmentarc.core.tasks.tasks.AbstractTask
	
	import com.voxelengine.Globals
	import com.voxelengine.renderer.Chunk
	import com.voxelengine.worldmodel.models.types.VoxelModel
	import com.voxelengine.worldmodel.Region
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class RenderingTask extends AbstractTask 
	{		
		public static const TASK_TYPE:String = "ABSTRACT_LANDSCAPE_TASK";
        public static const TASK_PRIORITY:int = 1;
		
		protected var _guid:String;
		protected var _chunk:Chunk;
		protected var _taskCount:int;
		protected var _time:int;
		
		public function RenderingTask( $guid:String, $chunk:Chunk, $taskType:String = TASK_TYPE, taskPriority:int = TASK_PRIORITY ):void {
			_guid = $guid;
			_chunk = $chunk;
			_taskCount++;
			super( $taskType, taskPriority);
			Globals.taskController.addTask( this );
			//Log.out( taskType + " task created for guid: " + $guid, Log.WARN);
		}

		override public function start():void {
			super.start();
			_time = getTimer();
		}

		override public function complete():void {
			_taskCount--;
			_chunk = null;
			//Log.out( taskType + " task took: " + ( getTimer() - _time ) + "  guid: " + _guid );
			super.complete();
		}
		
		protected function getVoxelModel():VoxelModel {
			return Region.currentRegion.modelCache.getModelFromModelGuid( _guid )			
		}
	}
}