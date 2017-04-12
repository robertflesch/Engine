/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.tasks.renderTasks
{
import com.voxelengine.events.OxelDataEvent;

import flash.utils.getTimer

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.renderer.Chunk

// Note that rendingTasks automatically add them selves to the queue.
public class RefreshFaces extends RenderingTask
{
    static public function addTask( $guid:String, $chunk:Chunk, $taskPriority:int ): void {
        new RefreshFaces( $guid, $chunk, $taskPriority );
    }

    public function RefreshFaces( $guid:String, $chunk:Chunk, $taskPriority:int ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( $guid, $chunk, "RefreshFaces", $taskPriority )
    }

    override public function start():void {
        super.start();
        Log.out("RefreshFaces.start: guid: " + _guid, Log.WARN);

        var time:int = getTimer();
        if ( _chunk )
            _chunk.oxel.facesBuild();
        var pt:int = (getTimer() - time);
        // if the processing time is less then 1 ms, do the next task
        OxelDataEvent.create( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, 0, _guid, null );
        super.complete();
        if ( pt < 1 ) {
            Log.out( "RefreshFaces.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms STARTING ANOTHER TASK", Log.WARN );
            Globals.taskController.next();
        }
        else
            Log.out( "RefreshFaces.start - refreshQuads guid: " + _guid + "  took: " + pt + " ms", Log.WARN );

    }
}
}
