/**
 * Created by dev on 4/12/2017.
 */
package com.voxelengine.worldmodel.models.makers {
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;

public class OxelLoadAndBuildManager {
    
    private var _op:OxelPersistence;
    private var _guid:String;
    private var _buildFaces:Boolean;
    
    public function OxelLoadAndBuildManager($guid:String, $op:OxelPersistence, $buildFaces:Boolean ):void {
        _guid = $guid;
        _op = $op;
        _buildFaces = $buildFaces;
    
        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
        OxelDataEvent.addListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
    
        FromByteArray.addTask(_guid, _op, FromByteArray.NORMAL_BYTE_LOAD_PRIORITY);
    }
    
    private function fromByteArrayComplete( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            Log.out("OxelLoadAndBuildManager.fromByteArrayComplete guid: " + _guid);
    
            var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
            OxelDataEvent.addListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            if ( _buildFaces ) {
                Log.out("OxelLoadAndBuildManager.fromByteArrayComplete build faces guid: " + _guid);
                VisitorFunctions.resetScaling( $ode.oxelData.oxel );
                _op.oxel.chunkGet().buildFaces(_guid, vm, true);
    
            } else {
                Log.out("OxelLoadAndBuildManager.fromByteArrayComplete build ONLY quads guid: " + _guid);
                OxelDataEvent.create(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, _op);
            }
        }
    }
    
    private function fromByteArrayFailed( $ode:OxelDataEvent ):void {
        if ( $ode.modelGuid == _guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_COMPLETE, fromByteArrayComplete );
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FBA_FAILED, fromByteArrayFailed );
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_FAILED, 0, _guid, null );
            Log.out("OxelLoadAndBuildManager.fromByteArrayFailed - ERROR in fromByteArray - guid" + _guid, Log.WARN);
            complete(); // AbstractTask will send event
        }
    }
    
    private function faceBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, faceBuildComplete );
            Log.out("OxelLoadAndBuildManager.faceBuildComplete guid: " + _guid);
    
            var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid(_guid);
            OxelDataEvent.addListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            _op.oxel.chunkGet().buildQuads(_guid, vm, true);
            OxelDataEvent.create( OxelDataEvent.OXEL_BUILD_COMPLETE, 0, _guid, _op );
        }
    }
    private function quadBuildComplete( $ode:OxelDataEvent ):void {
        if ($ode.modelGuid == _guid) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadBuildComplete );
            Log.out("OxelLoadAndBuildManager.quadBuildComplete guid: " + _guid, Log.INFO);
           complete();
        }
    }
    
    private function complete():void {
        Log.out("OxelLoadAndBuildManager.complete guid: " + _guid, Log.INFO);
    }
}
}
