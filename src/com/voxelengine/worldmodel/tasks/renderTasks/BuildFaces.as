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
import com.voxelengine.renderer.Chunk

// Note that rendingTasks automatically add them selves to the queue.
public class BuildFaces extends RenderingTask
{
    private var _forceFaces:Boolean;
    static public function addTask( $guid:String, $chunk:Chunk, $taskPriority:int, $forceRebuild:Boolean = false ): void {
        //Log.out("BuildFaces.addTask: guid: " + $guid + "  forceRebuild: " + $forceRebuild + "  taskPriority: " + $taskPriority, Log.WARN);
        new BuildFaces( $guid, $chunk, $taskPriority, $forceRebuild );
    }

    public function BuildFaces($guid:String, $chunk:Chunk, $taskPriority:int, $forceRebuild:Boolean ):void {
        // public function RenderingTask( $guid:String, $chunk:Chunk, taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
        _forceFaces = $forceRebuild;
        super( $guid, $chunk, "RefreshFaces", $taskPriority )
    }

    override public function start():void {
        super.start();
        //Log.out("BuildFaces.start: guid: " + _guid, Log.WARN);
        //Log.out("BuildFaces.start: guid: " + _guid  + "  gc: " + _chunk.gc + "  forceFaces: " + _forceFaces, Log.WARN);

        var time:int = getTimer();
        if ( _chunk )
            _chunk.oxel.facesBuild( _forceFaces );
        // if the processing time is less then 1 ms, do the next task
        OxelDataEvent.create( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, 0, _guid, null );
        super.complete();
    }
}
}
