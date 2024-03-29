/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine
{

import com.voxelengine.worldmodel.oxel.OxelBad;

import flash.utils.getTimer;

import com.furusystems.dconsole2.DConsole;
import com.furusystems.dconsole2.plugins.plugcollections.BasicPlugins;

import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.ControllableVoxelModel;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.tasks.landscapetasks.*;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;

public class ConsoleCommands {
	
	private static function setGC():void {
		if ( Globals.g_oxelBreakEnabled ) {
			Globals.oxelBreakDataReset();
			Log.out( "Selected Oxel break point is off", Log.WARN );
		}
		else {
			Globals.oxelBreakDataSet( EditCursor.currentInstance.gciData.gc );
			Log.out( "Selected Oxel break point is ON data: " + EditCursor.currentInstance.gciData.gc.toString(), Log.WARN );
		}
	}

	private static function reset():void {
		InstanceInfo.reset();
	}
	
	private static function trail():void {
		if ( VoxelModel.controlledModel )
		{
			var vm:ControllableVoxelModel = VoxelModel.controlledModel as ControllableVoxelModel;
			vm.leaveTrail = ! vm.leaveTrail;
			Log.out( "Trail is " + (vm.leaveTrail ? "ON" : "OFF"), Log.WARN );
		} else
			Log.out( "No model is under control to use trail on", Log.WARN );
	}
	
	private static function markers():void {
		if ( VoxelModel.controlledModel )
		{
			var vm:ControllableVoxelModel = VoxelModel.controlledModel as ControllableVoxelModel;
			vm.collisionMarkers = ! vm.collisionMarkers;
			Log.out( "CollisionPoints are " + (vm.collisionMarkers ? "ON" : "OFF"), Log.WARN );
		} else
			Log.out( "No model is under control to use collisionPoints on", Log.WARN );
	}
	
	private static function gravity():void {
		if ( VoxelModel.controlledModel ) {
			VoxelModel.controlledModel.usesGravity = ! VoxelModel.controlledModel.usesGravity;
			Log.out( "Gravity is " + (VoxelModel.controlledModel.usesGravity ? "ON" : "OFF"), Log.WARN );
		} else
			Log.out( "No model is under control to use gravity on", Log.WARN );
	}
	
	private static function trees( $change:int = 1000 ):void {
		if ( VoxelModel.selectedModel ) {
			//VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.growTreesOn( VoxelModel.selectedModel, TypeInfo.GRASS );
			VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.chunkGet().buildTrees( $change );

		} else
			Log.out( "No selected model", Log.WARN );
	}
	
	private static function tree():void {
		if ( VoxelModel.selectedModel ) {
			var oxel:Oxel = EditCursor.currentInstance.getHighlightedOxel();
			if ( OxelBad.INVALID_OXEL == oxel ) {
				Log.out( "Invalid location", Log.WARN );
				return;
			}

			Oxel.growTreeAt( VoxelModel.selectedModel, oxel );
//			TreeGenerator.generateTree( VoxelModel.selectedModel.instanceInfo.instanceGuid, oxel, 1 );
		} else
			Log.out( "No selected model", Log.WARN );
	}
	
	
	private static function sand():void {
		if ( VoxelModel.selectedModel ) {
			VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.dirtToGrassAndSand();
		} else
			Log.out( "No selected model", Log.WARN );
	}
	
	private static function vines():void {
		if ( VoxelModel.selectedModel ) {
			VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.vines( VoxelModel.selectedModel.instanceInfo.instanceGuid );
		} else
			Log.out( "No selected model", Log.WARN );
	}
	
	private static function lightingSun():void {
		/*
		if ( VoxelModel.selectedModel )
		{
			var ol:Vector.<Oxel> = new Vector.<Oxel>();
			VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.lightingSunGatherList( ol );
		}
		else {
			Log.out( "No selected model" );
			return;
		}
		
		var count:int;
		for each ( var oxel:Oxel in ol )
		{
			//if ( count < 200 )
				LightSunCheck.addTask( VoxelModel.selectedModel.instanceInfo.guid, oxel.gc, 1, Globals.POSY );
			//count++;
		}
		*/
	}
	
	private static function lightingReset():void
	{
		if ( VoxelModel.selectedModel ) {
			VoxelModel.visitor( VisitorFunctions.lightingReset, "Oxel.lightingReset" );
			VoxelModel.visitor( VisitorFunctions.rebuild, "Oxel.rebuild" );
		} else
			Log.out( "No selected model", Log.WARN );
	}
	
	private static function harvestTrees():void {
		if ( VoxelModel.selectedModel ) {
            VoxelModel.selectedModel.harvestTreesOn();
		}
		else
			Log.out( "No selected model", Log.WARN );
	}

	private static function harvestTreesOld():void {
		if ( VoxelModel.selectedModel ) {
			VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.harvestTrees( VoxelModel.selectedModel.instanceInfo.instanceGuid );
		}
		else
			Log.out( "No selected model", Log.WARN );
	}

	private static function collide():void
	{
		if ( VoxelModel.controlledModel )
		{
			VoxelModel.controlledModel.instanceInfo.usesCollision = !VoxelModel.controlledModel.instanceInfo.usesCollision;
			Log.out( "Collide is " + (VoxelModel.controlledModel.instanceInfo.usesCollision ? "ON" : "OFF"), Log.WARN );
		}
	}
	
	private static function flow():void
	{
		Globals.autoFlow = !Globals.autoFlow;
		Log.out( "autoFlow is " + (Globals.autoFlow ? "ON" : "OFF"), Log.WARN );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private static function tunnel():void
	{
		if ( !VoxelModel.selectedModel ) {
			Log.out( "ConsoleCommands.carveTunnel  No model selected", Log.WARN );
			return;
		}
		
		if ( !VoxelModel.selectedModel.instanceInfo ) {
			Log.out( "ConsoleCommands.carveTunnel  No instanceInfo for selected model", Log.WARN );
			return;
		}

		if ( !ModelCacheUtils.gci ) {
			Log.out( "ConsoleCommands.carveTunnel  No location selected", Log.WARN );
			return;
		}
			
		CarveTunnel.contructor( VoxelModel.selectedModel.instanceInfo.modelGuid
							  , ModelCacheUtils.gci.point
							  , ModelCacheUtils.viewVectorNormalizedGet()
							  , TypeInfo.AIR
							  , 2048
							  , 96 );
	}


	private static function tunnelNetworkDragon():void {
		tunnelNetwork( 2048, 96, 6 );
	}

	private static function tunnelNetwork( $tunnelLength:int = 2048, $tunnelSize:int = 96, $minSize:int = 4 ):void {
		if ( !VoxelModel.selectedModel ) {
			Log.out( "ConsoleCommands.CarveTunnels  No model selected", Log.WARN );
			return;
		}
		
		if ( !VoxelModel.selectedModel.instanceInfo ) {
			Log.out( "ConsoleCommands.CarveTunnels  No instanceInfo for selected model", Log.WARN );
			return;
		}

		if ( !ModelCacheUtils.gci ) {
			Log.out( "ConsoleCommands.CarveTunnels  No location selected", Log.WARN );
			return;
		}
			
		CarveTunnels.contructor( VoxelModel.selectedModel.instanceInfo.modelGuid
							   , ModelCacheUtils.gci.point
							   , ModelCacheUtils.viewVectorNormalizedGet()
							   , TypeInfo.AIR
							   , $tunnelLength
							   , $tunnelSize
							   , $minSize);
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	import flash.geom.Vector3D;
	
	private static function lavaSphere():void
	{
		
		var loc:Vector3D = ModelCacheUtils.gci.point;
		var vm:VoxelModel = VoxelModel.selectedModel;
		if ( !vm )
			{ Log.out( "ConsoleCommands.lavaSpheresCarve  No model selected", Log.WARN ); return; }
		
		spheresCarve( vm, loc, TypeInfo.LAVA );
	}
	
	private static function waterSphere():void
	{
		var loc:Vector3D = ModelCacheUtils.gci.point;
		var vm:VoxelModel = VoxelModel.selectedModel;
		if ( !vm )
			{ Log.out( "ConsoleCommands.waterSpheresCarve  No model selected", Log.WARN ); return; }

		spheresCarve( vm, loc, TypeInfo.WATER );
	}
	
	private static function lavaSpheres( $count:int = 10 ):void
	{
		var vm:VoxelModel = VoxelModel.selectedModel;
		if ( !vm )
			{ Log.out( "ConsoleCommands.lavaSpheresCarve  No model selected", Log.WARN ); return; }
		
		for ( var i:int=0; i < $count; i++ )
			spheresCarve( vm, Oxel.locationRandomGet( vm.modelInfo.oxelPersistence.oxel ), TypeInfo.LAVA );
	}
	
	private static function waterSpheres( $count:int = 10 ):void
	{
		var vm:VoxelModel = VoxelModel.selectedModel;
		if ( !vm )
			{ Log.out( "ConsoleCommands.waterSpheresCarve  No model selected", Log.WARN ); return; }

		for ( var i:int=0; i < $count; i++ )
			spheresCarve( vm, Oxel.locationRandomGet( vm.modelInfo.oxelPersistence.oxel ), TypeInfo.WATER );
	}
	
	private static function spheresCarve( $vm:VoxelModel, $loc:Vector3D, $type:int, $radius:int = 32, $minGrain:int = 2 ):void {
		var timer:int = getTimer();
		Oxel.nodes = 0;
		$vm.modelInfo.oxelPersistence.oxel.write_sphere( $vm.instanceInfo.instanceGuid
											   , $loc.x
											   , $loc.y
											   , $loc.z
											   , $radius 
											   , TypeInfo.AIR
											   , $minGrain );
		Log.out( "ConsoleCommands.waterSpheresCarve  carve AIR time: " + (getTimer() - timer) + "  change count: " + Oxel.nodes );
		timer = getTimer();
		$vm.modelInfo.oxelPersistence.oxel.writeHalfSphere( $vm.instanceInfo.instanceGuid
											   , $loc.x
											   , $loc.y
											   , $loc.z
											   , $radius 
											   , $type
											   , $minGrain );
		Log.out( "ConsoleCommands.waterSpheresCarve  carve mats time: " + (getTimer() - timer) );
		
		Oxel.merge( $vm.modelInfo.oxelPersistence.oxel );
	}
	
	private static function ambientOcculsion():void {
		Lighting.eaoEnabled = !Lighting.eaoEnabled;
		Log.out( "ambientOcculusion is " + (Lighting.eaoEnabled ? "ENABLED" : "DISABLED"), Log.WARN );
	}
	
	private static function recalculateAmbient():void {
		var vm:VoxelModel = VoxelModel.selectedModel;
		if ( vm )
			vm.modelInfo.oxelPersistence.oxel.recalculateAmbient( vm.modelInfo.guid )
	}
	
	public static function addCommands():void
	{
		DConsole.createCommand( "reset", reset );
		DConsole.createCommand( "setGC", setGC );
		DConsole.createCommand( "gravity", gravity );
		DConsole.createCommand( "collide", collide );
		DConsole.createCommand( "trail", trail );
		DConsole.createCommand( "trees", trees );
		DConsole.createCommand( "tree", tree );
		DConsole.createCommand( "sand", sand );
		DConsole.createCommand( "vines", vines );
		DConsole.createCommand( "lightingReset", lightingReset );
		DConsole.createCommand( "sun", lightingSun );
		DConsole.createCommand( "harvestTrees", harvestTrees );
		DConsole.createCommand( "harvestTreesOld", harvestTreesOld );
		DConsole.createCommand( "markers", markers );
		DConsole.createCommand( "flow", flow );
		
		DConsole.createCommand( "tunnel", tunnel );
		DConsole.createCommand( "tunnelNetwork", tunnelNetwork );
		DConsole.createCommand( "tunnelNetworkDragon", tunnelNetworkDragon );

		DConsole.createCommand( "lavaSpheres", lavaSphere );
		DConsole.createCommand( "waterSpheres", waterSphere );
		DConsole.createCommand( "lavaSpheresRandom", lavaSpheres );
		DConsole.createCommand( "waterSpheresRandom", waterSpheres );
		DConsole.createCommand( "ambientOcculsion", ambientOcculsion );
		DConsole.createCommand( "recalculateAmbient", recalculateAmbient );

		DConsole.registerPlugins(BasicPlugins);
	}
}
}