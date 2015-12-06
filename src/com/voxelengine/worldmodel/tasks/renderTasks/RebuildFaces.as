/*==============================================================================
  Copyright 2011-2015 Robert Flesch
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

/**
 * ...
 * @author Robert Flesch
 */
public class RebuildFaces extends RenderingTask 
{	
	static public function addTask( $guid:String, $chunk:Chunk ): void {
		if ( null == $chunk )
			return
		var rq:RebuildFaces = new RebuildFaces( $guid, $chunk )
		Globals.g_landscapeTaskController.addTask( rq )
	}
	
	public function RebuildFaces( $guid:String, $chunk:Chunk ):void {
		super( $guid, $chunk, "RebuildFaces")
	}
	
	override public function start():void {
		super.start()
		
		var time:int = getTimer()
		if ( _chunk )
			_chunk.refreshFacesTerminal()
		var pt:int = (getTimer() - time)
		// if the processing time is less then 1 ms, do the next task
		if ( pt < 1 ) {
			Globals.g_landscapeTaskController.next()
		}
		else
			Log.out( "RebuildFaces.start - took: " + pt, Log.WARN )
		
		super.complete()
	}
}
}
