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

import com.voxelengine.Log
import com.voxelengine.renderer.Chunk

// This builds the quads for a chunk as a task
public class BuildQuads extends RenderingTask
{
    private var _forceAll:Boolean;
    // Note that rendingTasks automatically add them selves to the queue.
    static public function addTask( $guid:String, $chunk:Chunk, $forceAll:Boolean, $taskPriority:int ): void {
        new BuildQuads( $guid, $chunk, $forceAll, $taskPriority );
    }

    public function BuildQuads( $guid:String, $chunk:Chunk, $forceAll:Boolean, $taskPriority:int ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        super( $guid, $chunk, "BuildQuads", $taskPriority )
        _forceAll = $forceAll;
    }

    override public function start():void {
        super.start();
        // This builds the quads from the oxels, and places them in rendering queue.
        if ( _forceAll )
            _chunk.oxel.quadsRebuildAllRecursively();
        else
            _chunk.oxel.quadsRebuildDirtyRecursively();
        OxelDataEvent.create( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, 0, _guid, null );
        super.complete();
    }
}
}
