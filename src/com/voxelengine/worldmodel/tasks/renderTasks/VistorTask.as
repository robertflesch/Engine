package com.voxelengine.worldmodel.tasks.renderTasks
{
import flash.utils.getTimer
import flash.utils.Timer

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.renderer.Chunk

/**
 * ...
 * @author Robert Flesch
 */
public class VistorTask extends RenderingTask 
{	
	public var _func:Function
	static public function addTask( $guid:String, $chunk:Chunk, $func:Function, $taskPriority:int ): void {
		var lt:VistorTask = new VistorTask( $guid, $chunk, $func, $taskPriority )
		Globals.g_landscapeTaskController.addTask( lt )
	}
	
	public function VistorTask( $guid:String, $chunk:Chunk, $func:Function, $taskPriority:int ):void {
		_func = $func
		// public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
		super( $guid, $chunk, "VistorTask", $taskPriority )
	}
	
	override public function start():void {
		super.start()
		
		var time:int = getTimer()
		if ( _chunk && _chunk.oxel )
			_func( _chunk.oxel )
		var pt:int = (getTimer() - time)
		// if the processing time is less then 1 ms, do the next task
		if ( pt < 1 )
			Globals.g_landscapeTaskController.next()
		//else	
		Log.out( "VistorTask took: " + pt, Log.DEBUG )
		
		super.complete()
	}
}
}