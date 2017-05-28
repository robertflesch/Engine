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

// This builds the quads for a chunk as a task
public class SkipTask extends RenderingTask
{
    // Note that rendingTasks automatically add them selves to the queue.
    static public function addTask(): void {
        //Log.out("SkipTask.addTask: guid: " + $guid + "  forceRebuild: " + $forceQuads + "  taskPriority: " + $taskPriority, Log.WARN);
        new SkipTask();
    }

    public function SkipTask():void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( "", null, "SkipTask", 10 );
    }

    override public function start():void {
        super.start();
        Log.out("SkipTask.start - complete", Log.WARN);
        super.complete();
    }
}
}
