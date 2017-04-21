/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers {
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;

import flash.utils.getTimer;

public class OxelLoadAndBuildManager {
    
    private var _op:OxelPersistence;
    private var _guid:String;
    private var _buildFaces:Boolean;
    private var _startTime:int = getTimer();
    private var _fbaTime:int;
    /*
    * Events generated for external consumption
    * OxelDataEvent.OXEL_BUILD_FAILED
    * OxelDataEvent.OXEL_BUILD_COMPLETE
     */
    public function OxelLoadAndBuildManager($guid:String, $op:OxelPersistence, $buildFaces:Boolean ):void {
        _guid = $guid;
        _op = $op;
        _buildFaces = $buildFaces;
    
        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
    
        FromByteArray.addTask(_guid, _op, FromByteArray.NORMAL_BYTE_LOAD_PRIORITY);
    }

    private function fromByteArrayFailed( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            Log.out("OxelLoadAndBuildManager.fromByteArrayFailed - ERROR in fromByteArray - guid" + _guid, Log.WARN);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_FAILED, 0, _guid, null );
        }
    }

    private function fromByteArrayComplete( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            _fbaTime = getTimer() - _startTime;
            //Log.out("OxelLoadAndBuildManager.fromByteArrayComplete guid: " + _guid + " time: " + _fbaTime );

            OxelDataEvent.addListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            OxelDataEvent.addListener(OxelDataEvent.OXEL_FACES_BUILT_FAIL, faceBuildFail );
            if ( _buildFaces ) {
                // This is an extra step that COULD be broken out, but since it rarely gets called
                // I will leave it as part of the fromByteArray subtask
                //Log.out("OxelLoadAndBuildManager.fromByteArrayComplete rescale AND schedule build faces tasks guid: " + _guid);
                _op.rescaleAndBuildFaces()
    
            } else {
                //Log.out("OxelLoadAndBuildManager.fromByteArrayComplete build ONLY quads guid: " + _guid);
                OxelDataEvent.create(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, _op);
            }
        }
    }

    private function faceBuildFail( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_FAIL, faceBuildFail );
            Log.out("OxelLoadAndBuildManager.faceBuildFail - ERROR in rescaleAndBuildFaces - guid" + _guid, Log.ERROR);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_FAILED, 0, _guid, null );
        }
    }

    private function faceBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            //Log.out("OxelLoadAndBuildManager.faceBuildComplete guid: " + _guid);
    
            OxelDataEvent.addListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            OxelDataEvent.addListener(OxelDataEvent.OXEL_QUADS_BUILT_FAIL, quadBuildFail );

            _op.buildQuads(true);
        }
    }

    private function quadBuildFail( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, faceBuildComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_FAIL, faceBuildFail );
            Log.out("OxelLoadAndBuildManager.faceBuildFail - ERROR in buildQuads - guid" + _guid, Log.ERROR);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_FAILED, 0, _guid, null );
        }
    }

    private function quadBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            //Log.out("OxelLoadAndBuildManager.quadBuildComplete guid: " + _guid, Log.INFO);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_COMPLETE, 0, _guid, _op );
        }
    }
    
}
}
