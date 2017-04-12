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
public class BuildQuads extends RenderingTask
{
    static public function addTask( $guid:String, $chunk:Chunk, $taskPriority:int ): void {
        //Log.out("BuildQuads.addTask: guid: " + $guid, Log.WARN);
        new BuildQuads( $guid, $chunk, $taskPriority );
    }

    public function BuildQuads( $guid:String, $chunk:Chunk, $taskPriority:int ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( $guid, $chunk, "BuildQuads", $taskPriority )
    }

    override public function start():void {
        var time:int = getTimer();
        super.start();
        //Log.out("BuildQuads.start: guid: " + _guid, Log.WARN);

        if ( _chunk ) {
            _chunk.oxel.quadsBuild();
            //Log.out("BuildQuads.start: guid: " + _guid + "  gc: " + _chunk.gc + "  chunk count: " + Chunk.chunkCount(), Log.WARN);
        }
        var pt:int = (getTimer() - time);
        // if the processing time is less then 1 ms, do the next task
        OxelDataEvent.create( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, 0, _guid, null );
        Log.out("BuildQuads.start: guid: " + _guid + "  childCount " + _chunk.oxel.childCount + " time: " + (getTimer()-time), Log.WARN);
        super.complete();
    }
}
}
