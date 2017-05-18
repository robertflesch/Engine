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

    /*
    * Events generated for external consumption
    * OxelDataEvent.OXEL_FBA_COMPLETE
    * OxelDataEvent.OXEL_FBA_FAILED
    * calls RebuildFacesAndQuads which generates
    * OxelDataEvent.OXEL_BUILD_FAILED
    * OxelDataEvent.OXEL_BUILD_COMPLETE
    *
    */
    public function OxelLoadAndBuildManager($guid:String, $op:OxelPersistence ):void {
        _guid = $guid;
        _op = $op;

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
            var forceFaces:Boolean = false;
            var forceQuads:Boolean = false;
            _op.oxel.chunkGet().faceAndQuadsBuild( forceFaces, forceQuads );
        }
    }
}
}
