/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks {
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.models.PersistenceObject;

import playerio.DatabaseObject;

public class TreeConfiguration extends PersistenceObject {
    public var POSXC:int;
    public var NEGXC:int;
    public var POSZC:int;
    public var NEGZC:int;

    public function get name():String             { return dbo.name; }
    public function get trunkType():uint          { return dbo.trunkType } //TypeInfo.BARK;
    public function get branchType():uint         { return dbo.branchType } //TypeInfo.BRANCH;
    public function get leafType():uint           { return dbo.leafType } // TypeInfo.LEAF;
    public function get interBranchDistance():int { return dbo.interBranchDistance } //3;
    public function get branchesPerSegment():int  { return dbo.branchesPerSegment } //2;
    public function get branchStartingLevel():int { return dbo.branchStartingLevel } //6;
    public function get trunkBaseHeight():int     { return dbo.trunkBaseHeight } //14;
    public function get trunkHeightVariation():int{ return dbo.trunkHeightVariation } //5;
    public function get leafBallAtTop():Boolean   { return dbo.leafBallAtTop }
    public function get leafBallSize():Number    { return dbo.leafBallSize }

    public function TreeConfiguration($guid:String, $dbo:DatabaseObject, $configObj:Object = null) {
        super($guid, Globals.BIGDB_TABLE_TREE_INFO);

        if (null == $dbo)
            assignNewDatabaseObject();
        else {
            dbo = $dbo;
        }

        init($configObj);
    }

    override protected function assignNewDatabaseObject():void {
        super.assignNewDatabaseObject();
    }

    private function init($configObj:Object):void {

        if ($configObj)
            mergeOverwrite($configObj);

    }

//        if ( $configObj ) {
//            if ( $configObj.name )
//                name = $configObj.name;
//            if ( $configObj.trunkType )
//                trunkType = $configObj.trunkType;
//            if ( $configObj.branchType )
//                branchType = $configObj.branchType;
//            if ( $configObj.leafType )
//                leafType = $configObj.leafType;
//
//            if ( $configObj.interBranchDistance )
//                interBranchDistance = $configObj.interBranchDistance;
//            if ( $configObj.branchesPerSegment )
//                branchesPerSegment = $configObj.branchesPerSegment;
//            if ( $configObj.branchesStartLevel )
//                branchStartingLevel = $configObj.branchesStartLevel;
//
//            if ( $configObj.trunkBaseHeight )
//                trunkBaseHeight = $configObj.trunkBaseHeight;
//            if ( $configObj.trunkHeightVariation )
//                trunkHeightVariation = $configObj.trunkHeightVariation;
//
//            if ( $configObj.leafBallAtTop )
//                leafBallAtTop = $configObj.leafBallAtTop;
//            if ( $configObj.leafBallSize )
//                leafBallSize = $configObj.leafBallSize
//        }


    public function canAdd($dir:int):Boolean {
        switch ($dir) {
            case Globals.POSX:
                return interBranchDistance <= POSXC;
                break;
            case Globals.NEGX:
                return interBranchDistance <= NEGXC;
                break;
            case Globals.POSZ:
                return interBranchDistance <= POSZC;
                break;
            case Globals.NEGZ:
                return interBranchDistance <= NEGZC;
                break;
        }
        return true;
    }

    public function inc():void {
        POSXC++;
        NEGXC++;
        POSZC++;
        NEGZC++;
    }

    public function reset($dir:int):void {
        switch ($dir) {
            case Globals.POSX:
                POSXC = 0;
                break;
            case Globals.NEGX:
                NEGXC = 0;
                break;
            case Globals.POSZ:
                POSZC = 0;
                break;
            case Globals.NEGZ:
                NEGZC = 0;
                break;
        }

    }

}
}