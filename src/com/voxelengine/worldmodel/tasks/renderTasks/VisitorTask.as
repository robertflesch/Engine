/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.tasks.renderTasks
{
import flash.utils.getTimer
import flash.utils.Timer

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.renderer.Chunk

// Note that rendingTasks automatically add them selves to the queue.
public class VisitorTask extends RenderingTask
{	
	public var _func:Function;
	private var _taskName:String;
	static public function addTask( $guid:String, $chunk:Chunk, $func:Function, $taskPriority:int, $taskName:String = "" ): void {
		new VisitorTask( $guid, $chunk, $func, $taskPriority, $taskName )
	}
	
	public function VisitorTask($guid:String, $chunk:Chunk, $func:Function, $taskPriority:int, $taskName:String ):void {
		_func = $func;
		_taskName = $taskName;
		// public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
		super( $guid, $chunk, "VisitorTask", $taskPriority )
	}
	
	override public function start():void {
		super.start();
		
		var time:int = getTimer();
		if ( _chunk && _chunk.oxel )
			_func( _chunk.oxel );
		var pt:int = (getTimer() - time);
		// if the processing time is less then 1 ms, do the next task
		if ( pt < 1 )
			Globals.g_landscapeTaskController.next();
		//else	
		Log.out( "VisitorTask.func: " + _taskName + " chunkSize: " + ( (_chunk && _chunk.oxel) ? _chunk.oxel.childCount : 0) +  "  took: " + pt, Log.DEBUG )
		
		super.complete()
	}
}
}
