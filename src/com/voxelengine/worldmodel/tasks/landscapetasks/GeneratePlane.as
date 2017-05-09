/**
 * Created by dev on 5/8/2017.
 */
package com.voxelengine.worldmodel.tasks.landscapetasks {
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;

import flash.utils.getTimer;

public class GeneratePlane extends LandscapeTask
{
    public function GeneratePlane( guid:String, layer:LayerInfo ):void {
        trace( "GeneratePlane.construct of type: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
        super(guid, layer, "GeneratePlane");
    }

    override public function start():void
    {
        super.start(); // AbstractTask will send event

        var timer:int = getTimer();

        //////////////////////////////////////////////////////////
        // Builds Solid Cube of any grain size
        //////////////////////////////////////////////////////////
        var vm:VoxelModel = getVoxelModel();
        var root_grain_size:uint = vm.metadata.bound;
        var min_grain_size:int = root_grain_size - _layer.range;
        if ( 0 > min_grain_size || min_grain_size > root_grain_size || ( 8 < (root_grain_size - min_grain_size)) )
        {
            min_grain_size = Math.max( 0, root_grain_size - 4 );
            trace( "GeneratePlane.start - WARNING - Adjusting range: " + min_grain_size );
        }

        trace("GeneratePlane.start on rootGrain of max size: " + root_grain_size + "  Filling with grain of size: " + min_grain_size + " of type: " + TypeInfo.typeInfo[_layer.type].name );
        var loco:GrainCursor = GrainCursorPool.poolGet(vm.modelInfo.oxelPersistence.oxel.gc.bound);

        var size:int = 1 << (root_grain_size - min_grain_size);
        for ( var x:int = 0; x < size; x++ ) {
            for ( var y:int = 0; y < size; y++ ) {
                for ( var z:int = 0; z < size; z++ ) {
                    vm.write( loco.set_values( x, y, z, min_grain_size ), _layer.type, true );
                }
            }
        }
        GrainCursorPool.poolDispose( loco );

        //vm.print();

        trace( "GeneratePlane.start - took: "  + (getTimer() - timer) );
        super.complete() // AbstractTask will send event
    }

    override public function cancel():void {
        // TODO stop this somehow?
        super.cancel();
    }
}
}
