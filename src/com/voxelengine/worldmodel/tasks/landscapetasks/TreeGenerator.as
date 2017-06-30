/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
import com.voxelengine.Globals;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.OxelBad;

/**
 * ...
 * @author Robert Flesch
 */
public class  TreeGenerator
{
	public static function generateTree( $guid:String, oxel:Oxel, $chance:int = 2000 ):Boolean {
		// by default the chance is 1/2000
		var chance:Number = 1 / $chance;
		if ( chance > Math.random() ) {
//				if ( 0.5 > Math.random() )
//					buildPineTree( $guid, oxel );
//				else
			var configObj:Object = {};
			configObj.name = "TestConfig";
			configObj.trunkType = TypeInfo.BARK;
			configObj.branchType = TypeInfo.BRANCH;
			configObj.leafType = TypeInfo.LEAF;

			configObj.interBranchDistance = 3;
			configObj.branchesPerSegment = 2;
			configObj.branchStartingLevel = 3;

			configObj.trunkBaseHeight = 14;
			configObj.trunkHeightVariation = 5;
			configObj.leafBallAtTop = true;
			configObj.leafBallSize = 32;

			var tc:TreeConfiguration = new TreeConfiguration( Globals.getUID(), null, configObj );
			return buildTree( tc, $guid, oxel );
		}
		return false;
	}

	private static function roomToGrow( $oxel:Oxel, trunk:int ):int {

		// Todo - check to make sure we are not growing into something?
		var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound );
		gct.copyFrom( $oxel.gc );
		var hasRoomToGrow:Boolean = true;
		for ( var i:int = 0; i < trunk; i ++ ) {
			hasRoomToGrow = gct.move_posy();
			if ( !hasRoomToGrow )
				break;
		}
		GrainCursorPool.poolDispose( gct );
		return i;
	}

	private static function buildTree( $tc:TreeConfiguration, $guid:String, $oxel:Oxel ):Boolean {

		var trunkHeightDesired:int = $tc.trunkBaseHeight + Math.random() * $tc.trunkHeightVariation;

		// Make sure top is not cut off AND
		var trunkHeightAvailable:int = roomToGrow($oxel, trunkHeightDesired);
		if ( trunkHeightAvailable <= trunkHeightDesired * 0.5) {
			Log.out( "TreeGenerator.buildTree - NOT ENOUGH ROOM", Log.WARN);
			return false;
		}

		// this returns gct at the top of the trunk
		buildTrunk( $tc, $guid, $oxel, trunkHeightAvailable );
		buildBranches( $tc, $guid, $oxel, trunkHeightAvailable );
		return true;
	}

	// this returns gct at the top of the trunk
	public static function buildTrunk( $tc:TreeConfiguration, $guid:String, $oxel:Oxel, trunkHeight:int ): void
	{
		var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound );
		gct.copyFrom( $oxel.gc );
		gct.move_posy();
		var ao:Oxel;
		for ( var currentHeight:int = 0; currentHeight < trunkHeight; currentHeight++ ) {
			ao = $oxel.root_get().childGetOrCreate( gct );
			if ( ao == OxelBad.INVALID_OXEL ) {
				GrainCursorPool.poolDispose(gct);
				return;
			}
			ao.change($guid, gct, $tc.trunkType);
			gct.move_posy();
		}
		if ( $tc.leafBallAtTop )
			addLeaves( $tc, $guid, Globals.POSY, ao, (0.01875 * $tc.leafBallSize) );
		GrainCursorPool.poolDispose( gct );
	}

	private static function buildBranches( $tc:TreeConfiguration, $guid:String, $oxel:Oxel, trunkHeight:int ):void {
		var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound );
		gct.copyFrom( $oxel.gc );
		for (var trunkLevel:int = 0; trunkLevel < trunkHeight; trunkLevel++) {
			if ( trunkLevel < $tc.branchStartingLevel ){
				gct.move_posy();
				$tc.inc();
				continue;
			}
			var ao:Oxel = $oxel.root_get().childGetOrCreate( gct );
			var dir:int = Globals.randomHorizontalDirection();
			var branchesAdded:int = 0;
			for ( var i:int = 0; i < 4; i++ ) {
				if ( $tc.canAdd(dir) ) {
					trace( "TreeGenerator.buildBranches build in dir: " + dir );
					branchesAdded++;
					addBranch( $tc, $guid, dir, ao, trunkHeight, trunkLevel);
					$tc.reset(dir);
				}
				dir = Globals.nextHorizontalDirection( dir );
				if ( $tc.branchesPerSegment <= branchesAdded )
						break;
			}
			gct.move_posy();
			$tc.inc();
		}
	}

	public static function addBranch( $tc:TreeConfiguration, $guid:String, $dir:int, $oxel:Oxel, $trunkHeight:Number, $currentHeight:Number ): void {
		var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound );
		gct.copyFrom( $oxel.gc );
		gct.become_child( 0 );
		// if we are close to the top, make small branch
		if ( $trunkHeight * 0.75 <= $currentHeight )
			gct.become_child( 0 );
		var d:Array = Globals.orthagonalDirections( $dir );
		var sideDir:int = Math.random() > 0.5 ? d[0] : d[1];
		var ao:Oxel;
		var side:Boolean = true; // so branch moves to side only once per 2 forwards
		for ( var t:int = 0; t < $currentHeight; t++ ) {
			if ( Math.random() > 0.7 && side == false ){
				side = true;
				gct.move( sideDir );
				ao = $oxel.root_get().childGetOrCreate( gct );

				if ( OxelBad.INVALID_OXEL == ao ) {
					GrainCursorPool.poolDispose( gct );
					return;
				}
				ao.change($guid, gct, $tc.branchType);
			}
			else {
				side = false;
			}
			gct.move( $dir );
			ao = $oxel.root_get().childGetOrCreate( gct );
			if ( OxelBad.INVALID_OXEL == ao ) {
				GrainCursorPool.poolDispose( gct );
				return;
			}
			ao.change($guid, gct, $tc.branchType);
		}
		addLeaves( $tc, $guid, $dir, ao, $currentHeight/$trunkHeight );
		GrainCursorPool.poolDispose( gct );
	}

	public static function addLeaves( $tc:TreeConfiguration, $guid:String, $dir:int, $oxel:Oxel, $relativeHeight:Number ): void {
		var gct:GrainCursor = GrainCursorPool.poolGet( $oxel.gc.bound );
		gct.copyFrom( $oxel.gc );
		var worldSize:int = gct.size();
		var xCoord:int = gct.getModelX() + worldSize/2;
		var zCoord:int = gct.getModelZ() + worldSize/2;
		gct.move( $dir );
		gct.become_ancestor( 1 );
		var ao:Oxel = $oxel.root_get().childGetOrCreate( gct );
		//var ballSize:Number = gct.size() * Math.max( $relativeHeight, 2.5 );
		var ballSize:Number = $relativeHeight * 60;
		trace( "TreeGenerator.ballSize: " + ballSize + " relativeHeight: " + $relativeHeight );
		if ( OxelBad.INVALID_OXEL != ao ) {
			//ao.change($guid, gct, e_leafType);
			$oxel.root_get().write_sphere( $guid
					, xCoord
					, gct.getModelY() + worldSize/4
					, zCoord
					, ballSize
					, $tc.leafType
					, 3
					, true );
		}
		GrainCursorPool.poolDispose( gct );
	}
}
}

