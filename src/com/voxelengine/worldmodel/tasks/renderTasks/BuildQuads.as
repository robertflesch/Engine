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

public class BuildQuads extends RenderingTask
{
    static public function addTask( $guid:String, $chunk:Chunk, $taskPriority:int ): void {
        var rq:BuildQuads = new BuildQuads( $guid, $chunk, $taskPriority );
        Globals.g_landscapeTaskController.addTask( rq )
    }

    public function BuildQuads( $guid:String, $chunk:Chunk, $taskPriority:int ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( $guid, $chunk, "BuildQuads", $taskPriority )
    }

    override public function start():void {
        super.start();
        Log.out("BuildQuads.start: guid: " + _guid, Log.WARN);

        var time:int = getTimer();
        if ( _chunk )
            _chunk.oxel.quadsBuild();
        var pt:int = (getTimer() - time);
        // if the processing time is less then 1 ms, do the next task
        super.complete();
        if ( pt < 1 ) {
            Log.out( "BuildQuads.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms STARTING ANOTHER TASK", Log.WARN );
            Globals.g_landscapeTaskController.next();
        }
        else
            Log.out( "BuildQuads.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms", Log.WARN );

    }
}
}
