/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers {
import com.voxelengine.events.LevelOfDetailEvent;
import com.voxelengine.worldmodel.models.OxelPersistance;

import flash.utils.ByteArray;

public class OxelCloner {
    public function OxelCloner( $op:OxelPersistance ) {
        // this adds the version header, need for the persistanceEvent
        var ba:ByteArray = OxelPersistance.toByteArray( $op.oxel );
        // We want to write the copy into the new lod, and reduce it from there.
        $op.incrementLOD();
        $op.lodFromByteArray( ba );

        // the clone should be set to the current oxel , this should be called on the clone
        var lodCount:int = $op.lodModelCount();
        var minGrain:int = lodCount + 3;
        //$op.oxel.print();
        $op.oxel.generateLOD( minGrain );
        //$op.oxel.print();
        // Only needed for current oxel or testing
        // but only top most oxel can be modified, and lower level ones are only generated on saving.//
        // Oxel.rebuild( oxel );

        LevelOfDetailEvent.dispatch( new LevelOfDetailEvent( LevelOfDetailEvent.MODEL_CLONE_COMPLETE ) );
    }
}
}
