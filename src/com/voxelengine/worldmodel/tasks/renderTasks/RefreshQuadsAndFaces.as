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

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.renderer.Chunk

/**
 * ...
 * @author Robert Flesch
 */
public class RefreshQuadsAndFaces extends RenderingTask 
{	
	static public function addTask( $guid:String, $chunk:Chunk, $taskPriority:int ): void {
		var rq:RefreshQuadsAndFaces = new RefreshQuadsAndFaces( $guid, $chunk, $taskPriority );
		Globals.g_landscapeTaskController.addTask( rq )
	}
	
	public function RefreshQuadsAndFaces( $guid:String, $chunk:Chunk, $taskPriority:int ):void {
		// public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
		super( $guid, $chunk, "RefreshQuadsAndFaces", $taskPriority )
	}
	
	override public function start():void {
		super.start();
		Log.out("RefreshQuadsAndFaces.start: guid: " + _guid, Log.WARN);

		var time:int = getTimer();
		if ( _chunk )
			_chunk.refreshFacesAndQuadsTerminal();
		var pt:int = (getTimer() - time);
		// if the processing time is less then 1 ms, do the next task
		super.complete();
		if ( pt < 1 ) {
			Log.out( "RefreshQuadsAndFaces.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms STARTING ANOTHER TASK", Log.WARN );
			Globals.g_landscapeTaskController.next();
		}
		else
			Log.out( "RefreshQuadsAndFaces.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms", Log.WARN );
		
	}
}
}
