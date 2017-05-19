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
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.renderer.Chunk

// This builds the quads for a chunk as a task
public class BuildQuads extends RenderingTask
{
    private var _forceQuads:Boolean;
    // Note that rendingTasks automatically add them selves to the queue.
    static public function addTask( $guid:String, $chunk:Chunk, $forceQuads:Boolean, $taskPriority:int ): void {
        //Log.out("BuildQuads.addTask: guid: " + $guid + "  forceRebuild: " + $forceQuads + "  taskPriority: " + $taskPriority, Log.WARN);
        new BuildQuads( $guid, $chunk, $forceQuads, $taskPriority );
    }

    public function BuildQuads( $guid:String, $chunk:Chunk, $forceQuads:Boolean, $taskPriority:int ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( $guid, $chunk, "BuildQuads", $taskPriority );
        _forceQuads = $forceQuads;
    }

    override public function start():void {
        super.start();
        //Log.out("BuildQuads.start: guid: " + _guid + "  gc: " + _chunk.gc  + "  forceQuads: " + _forceQuads, Log.WARN);
        // This builds the quads from the oxels, and places them in rendering queue.
        _chunk.oxel.quadsBuild( _forceQuads );
        OxelDataEvent.create( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, 0, _guid, null );
        super.complete();
    }
}
}
