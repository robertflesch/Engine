/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
import com.voxelengine.Log;
import com.voxelengine.worldmodel.tasks.flowtasks.*;

import com.voxelengine.worldmodel.tasks.renderTasks.*;

import flash.utils.getDefinitionByName;

public class TaskLibrary
{
	public static function getAsset ( assetLinkageID : String ) : Class
	{
		//noinspection BadExpressionStatementJS
        GenerateLayer; // Tested
		//noinspection BadExpressionStatementJS
        CarveOutsideSurface; // Tested
		//noinspection BadExpressionStatementJS
        CarveOutsideSurfaceNoTaper; // Tested
		//noinspection BadExpressionStatementJS
        CarveOutsideVolcano; //
		//noinspection BadExpressionStatementJS
        MergeLayer;
		//noinspection BadExpressionStatementJS
        LoadingImageDisplay;
		//noinspection BadExpressionStatementJS
        LoadingImageDestroy;
		//noinspection BadExpressionStatementJS
        CarveTunnel; // One tunnel starting at edit cursor location
		//noinspection BadExpressionStatementJS
        CarveTunnels;
		//noinspection BadExpressionStatementJS
        GrowTreesOn; // Tested
		//noinspection BadExpressionStatementJS
        GrowTreesOnAnything;
		//noinspection BadExpressionStatementJS
        GenerateWater;
		//noinspection BadExpressionStatementJS
        GenerateCube;
		//noinspection BadExpressionStatementJS
        GenerateSphere;
		//noinspection BadExpressionStatementJS
        LoadModelFromIVM;
		//noinspection BadExpressionStatementJS
        Flow;
		//noinspection BadExpressionStatementJS
        DirtToGrassAndSand;


		/// old or untested
		//noinspection BadExpressionStatementJS
        GenerateGrassAndTrees; // Old
		//noinspection BadExpressionStatementJS
        GenerateVolcano; //
		//noinspection BadExpressionStatementJS
        GenerateLavaPockets;

		//noinspection BadExpressionStatementJS
        GenerateSubSphere;
		//noinspection BadExpressionStatementJS
        LandscapeError;
		//noinspection BadExpressionStatementJS
        GenerateClouds;
		//noinspection BadExpressionStatementJS
        CarveCloudOutside;

		var asset:Class = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeError" ) );
		try
		{
			asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.tasks.landscapetasks." + assetLinkageID ) );
		}
		catch ( error:Error )
		{
			Log.out( "TaskLibrary.getAsset - ERROR - ERROR - ERROR: " + error + " was looking for: com.voxelengine.worldmodel.tasks.landscapetasks." + assetLinkageID, Log.ERROR );
		}



		//var asset : Class = Class ( getDefinitionByName ( "VoxelVerse" ) ) ;
		// This works
		//asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.VoxelModel" ) ) ;
		// This don't!
		//asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.tasks.Flow" ) ) ;
		//asset = Class ( getDefinitionByName ( assetLinkageID ) ) ;
		//
		return asset;
	}

	public static function getAssetNames():Object
	{
		return {
			//CarveTunnels:			CarveTunnels,
			//CarveOutsideSurface:    CarveOutsideSurface,
			//GenerateGrassAndTrees:  GenerateGrassAndTrees,
			//GenerateLavaPockets:    GenerateLavaPockets,
			//GenerateCube:           GenerateCube,
			//GenerateSphere:         GenerateSphere,
			//LandscapeError:         LandscapeError,
			//LoadModelFromIVM:       LoadModelFromIVM,
			//AddAxes:                AddAxes,
			//GenerateClouds:         GenerateClouds,
			//CarveCloudOutside:      CarveCloudOutside,
			//CreatePlayer:           CreatePlayer
			GenerateLayer:          GenerateLayer,
			GenerateWater:          GenerateWater
		}
	}

}
}

