/**
 * Created by dev on 6/27/2017.
 */
package com.voxelengine.worldmodel.tasks.landscapetasks {
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.TypeInfo;

import flash.utils.ByteArray;

public class GenerateTree extends LandscapeTask {
    static public function script($grain:int, $type:int = 112, $lockLight:Boolean = false):Object {
        if (0 == $type)
            $type = TypeInfo.SAND;
        var model:Object = {};
        model.name = "GenerateTree";
        model.grainSize = $grain;
        model.lockLight = $lockLight;

        var nBiomes:Object = {};
        nBiomes.layers = new Vector.<Object>();
        nBiomes.layers[0] = {};
        nBiomes.layers[0].functionName = "GenerateTree";
        nBiomes.layers[0].type = $type;
        model.biomes = nBiomes;

        return model;
    }

    static public function addTask($guid:String, layer:LayerInfo, $taskPriority:int = 5 ):void {
        var genCube:GenerateTree = new GenerateTree($guid, layer, $taskPriority);
        Globals.taskController.addTask(genCube);
    }

    // HAS to be public, but should NEVER be called
    public function GenerateTree($guid:String, layer:LayerInfo, $taskPriority:int):void {
        super($guid, layer, "GenerateTree", $taskPriority);
    }

    override public function start():void {
        super.start();
        //Log.out("GenerateTree.start");
        // This generates a GENERATION_SUCCESS, which is picked up by the OxelPersistenceCache
        // which then starts the build process

        //////////////////////////////////////////////////////////
        // Builds Solid Cube of any grain size
        //////////////////////////////////////////////////////////
        var rootGrain:int = _layer.offset;
        var oxel:Oxel = Oxel.initializeRoot( rootGrain );
        //
        var minGrain:int = rootGrain - 1;
        if ( rootGrain < 0 || minGrain < 0 || minGrain > rootGrain || ( 8 < (rootGrain - minGrain)) ) {
            minGrain = Math.max( 0, rootGrain - 4 );
            Log.out( "Oxel.generateCube - WARNING - Adjusting range: " + minGrain, Log.WARN );
        }

        //trace("GenerateTree.start on rootGrain of max size: " + rootGrain + "  Filling with grain of size: " + minGrain + " of type: " + Globals.Info[_layer.type].name );
        var gct:GrainCursor = GrainCursorPool.poolGet(rootGrain);
        var size:int = 1 << (rootGrain - minGrain);
        for ( var x:int = 0; x < size; x++ ) {
            for ( var y:int = 0; y < size; y++ ) {
                for ( var z:int = 0; z < size; z++ ) {
                    gct.set_values( x, y, z, minGrain );
                    oxel.change( _modelGuid, gct, TypeInfo.AIR, true );
                }
            }
        }

        oxel.markBoundaries( _modelGuid );
        var center:uint = gct.size();
        gct.grainX = center;
        gct.grainY = 0;
        gct.grainZ = center;
        gct.grain = 0;
        gct.become_ancestor(4);
        // this places a dirt block on the bottom center.
        var rootOxel:Oxel = oxel.change( _modelGuid, gct, TypeInfo.DIRT, true );
        TreeGenerator.generateTree( _modelGuid, rootOxel, 1 );

        GrainCursorPool.poolDispose( gct );
        oxel.dirty = true;
        // CRITICAL STEP. oxels are expected to have faces, not dirty faces
        // So this step turns the dirty faces into real faces.
        // for multistep island builds I will have to ponder this more.
        // TODO Ahhhh, you have to build faces HERE AND NOW
        // Since the toByteArray does NOT save dirty bits!!!!
        oxel.facesBuild();
        var ba:ByteArray = oxel.toByteArray();
//			Log.out( "GenerateTree finished object: " + Hex.fromArray( ba, true ) );
//			Log.out( "GenerateTree finished compressed object: " + Hex.fromArray( ba, true ) );
        //Log.out( "GenerateTree finished modelGuid: " + _modelGuid );

        PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.GENERATE_SUCCEED, 0, Globals.IVM_EXT, _modelGuid, null, ba, null, rootGrain.toString() ) );
        super.complete();
    }
}
}
