/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
import com.developmentarc.core.tasks.tasks.AbstractTask;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;

public class OxelLoadAndBuildTasks extends AbstractTask {

    private var _op:OxelPersistence;
    private var _guid:String;
    private var _buildFaces:Boolean;

    static private const PRIORITY:int = 5;
    static public function addTask($guid:String, $op:OxelPersistence, $taskPriority:int = PRIORITY, $buildFaces:Boolean = false):void {
        var genCube:OxelLoadAndBuildTasks = new OxelLoadAndBuildTasks($guid, $op, $taskPriority, $buildFaces);
        Globals.g_landscapeTaskController.addTask(genCube);
    }

    public function OxelLoadAndBuildTasks($guid:String, $op:OxelPersistence, $taskPriority:int, $buildFaces:Boolean ):void {
        super( "OxelLoadAndBuildTasks", $taskPriority);
        _guid = $guid;
        _op = $op;
        _buildFaces = $buildFaces;
    }

    override public function start():void {
        super.start(); // AbstractTask will send event

        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );

        FromByteArray.addTask(_guid, _op, FromByteArray.NORMAL_BYTE_LOAD_PRIORITY);
    }

    private function fromByteArrayComplete( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            Log.out("OxelLoadAndBuildTasks.fromByteArrayComplete guid: " + _guid);

            var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
            OxelDataEvent.addListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            if ( _buildFaces ) {
                Log.out("OxelLoadAndBuildTasks.fromByteArrayComplete build faces guid: " + _guid);
                VisitorFunctions.resetScaling( $ode.oxelData.oxel );
                _op.oxel.chunkGet().buildFaces(_guid, vm, true);

            } else {
                Log.out("OxelLoadAndBuildTasks.fromByteArrayComplete build ONLY quads guid: " + _guid);
                OxelDataEvent.create(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, _op);
            }
        }
    }

    private function fromByteArrayFailed( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_FAILED, 0, _guid, null );
            Log.out("OxelLoadAndBuildTasks.fromByteArrayFailed - ERROR in fromByteArray - guid" + _guid, Log.WARN);
            super.complete(); // AbstractTask will send event
        }
    }

    private function faceBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            Log.out("OxelLoadAndBuildTasks.faceBuildComplete guid: " + _guid);

            var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid(_guid);
            OxelDataEvent.addListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            _op.oxel.chunkGet().buildQuads(_guid, vm, true);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_COMPLETE, 0, _guid, _op );
        }
    }
    private function quadBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            Log.out("OxelLoadAndBuildTasks.quadBuildComplete guid: " + _guid, Log.INFO);
            super.complete();
        }
    }
}
}
