/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.oxel {
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.pools.LightingPool;
import com.voxelengine.worldmodel.TypeInfo;

public class VisitorFunctions {
    public function VisitorFunctions() {
    }

    static public function rebuildGrass( $oxel:Oxel ):void {
        if ( $oxel.childrenHas() ) {
            for each ( var child:Oxel in $oxel.children )
                rebuildGrass( child ); }
        else {
            if ( TypeInfo.GRASS == $oxel.type ) {
                if ( $oxel.gc.eval( 4, 64, 89, 13 ) )
                    Log.out( "VisitorFunctions.rebuildGrass - why doesnt this change?" );
                // look above this oxel
                var no:Oxel = $oxel.neighbor( Globals.POSY );
                // if its air, ok
                if ( TypeInfo.hasAlpha( no.type ) && !no.childrenHas() )
                    return;
                // if its has children, and one of those is air
                // change it to dirt, and create children
                if ( no.type == TypeInfo.AIR && no.childrenHas() ) {
                    if ( no.faceHasAlpha( Globals.NEGY ) ) {
                        // no has alpha and children, I need to change to dirt and break up, and revaluate
                        $oxel.type = TypeInfo.DIRT;
                        $oxel.childrenCreate( true );
                        for each ( var dchild:Oxel in $oxel.children )
                            dchild.evaluateForChangeToGrass()
                    }
                    else
                        $oxel.type = TypeInfo.DIRT
                }
                else if ( !TypeInfo.hasAlpha( no.type ) ) {
                    $oxel.type = TypeInfo.DIRT
                }
                else if ( no.childrenHas() ) {
                    Log.out( "VisitorFunctions.rebuildGrass - invalid condition: no.type" + no.type, Log.ERROR )
                }
                else
                    Log.out( "VisitorFunctions.rebuildGrass - invalid condition", Log.ERROR )
            }
        }
    }

    // This rebuilds the oxel and its children.
    // if used in a lambda function, it rebuilds the entire model
    static public function rebuild( $oxel:Oxel ):void {
        if ( $oxel.childrenHas() ) {
            if ( TypeInfo.AIR != $oxel.type ) {
                Log.out( "VisitorFunctions.rebuildAll - parent with TYPE: " + TypeInfo.typeInfo[$oxel.type].name, Log.ERROR );
                $oxel.type = TypeInfo.AIR;
            }
            for each ( var child:Oxel in $oxel.children )
                rebuild(child);
        }
        else {
            $oxel.facesMarkAllDirty();
            $oxel.quadsDeleteAll();
            $oxel.facesBuildTerminal();
        }
    }

    static public function rebuildLightingRecursive( $oxel:Oxel ):void {
        if ($oxel.childrenHas()) {
            for each (var child:Oxel in $oxel.children)
                rebuildLightingRecursive( child );
        }
        else {
            if ( $oxel.facesHas() ) {
                if ( !$oxel.lighting ) {
                    $oxel.lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
                    $oxel.lighting.add( $oxel.chunkGet().lightInfo ); // Get the parent chunk
                }
                $oxel.dirty = true;
                $oxel.quadsRebuildAll();
            }
        }
    }

    static public function rebuildWater( $oxel:Oxel ):void {
        if ( $oxel.childrenHas() ) {
            for each ( var child:Oxel in $oxel.children )
                rebuildWater( child ); }
        else {
            if ( TypeInfo.WATER == $oxel.type ) {
                if ( 5 < $oxel.gc.grain ) {
                    Log.out( "VisitorFunctions.rebuildWater found grain too large: " + $oxel.gc.toString() );
                    $oxel.childrenCreate( true );
                    for each ( var newChild:Oxel in $oxel.children )
                        rebuildWater( newChild )
                } else {
                    var no:Oxel;
                    // This finds edges of bottoms that are open to free flowing and turns them to sand
                    for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
                        if ( Globals.isHorizontalDirection( face ) || Globals.NEGY == face ) {
                            no = $oxel.neighbor(face);
                            if ( Globals.BAD_OXEL == no )
                                $oxel.type = TypeInfo.SAND;
                            else if ( TypeInfo.AIR == no.type && !no.childrenHas() )
                                $oxel.type = TypeInfo.SAND;
                        }
                    }

                    $oxel.facesMarkAllDirty();
                    $oxel.quadsDeleteAll();
                }
            }
        }
    }

    static public function resetScaling( $oxel:Oxel ):void {
        if ($oxel.childrenHas()) {
            for each (var child:Oxel in $oxel.children)
                resetScaling(child);
        }
        else {
            if (Globals.BAD_OXEL == $oxel)
                return;
            if ($oxel.flowInfo && $oxel.flowInfo.flowScaling && $oxel.flowInfo.flowScaling.has()) {
//                if (TypeInfo.flowable[$oxel.type])
//                    return;

                $oxel.flowInfo.flowScaling.reset();
				$oxel.facesMarkAllDirty();
                $oxel.quadsDeleteAll();
            }
        }
    }

    static public function lightingReset( $oxel:Oxel ):void {

        if ( $oxel.childrenHas() ) {
            for each ( var child:Oxel in $oxel.children )
                VisitorFunctions.lightingReset( child );
        }
        else if ( $oxel.lighting ) {
            if ( $oxel.lighting.reset() )
                $oxel.quadsRebuildAll();
        }
    }
} // end of class Oxel
} // end of package
