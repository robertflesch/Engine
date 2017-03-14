/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.biomes
{

import com.voxelengine.worldmodel.tasks.landscapetasks.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.developmentarc.core.tasks.tasks.ITask;
import com.developmentarc.core.tasks.groups.TaskGroup;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class Biomes
{
	private var _createHeightMap:Boolean = false; // NOT USED
	private var _layers:Vector.<LayerInfo> = new Vector.<LayerInfo>;

	// getters/setters
	public function isEmpty():Boolean { return 0 == _layers.length; }
	public function get layers():Vector.<LayerInfo> { return _layers; }

	public function Biomes( createHeightMap:Boolean = false ) {
		// This allows me to use heightmap larger then a single region
		_createHeightMap = createHeightMap;
	}

	public function clone():Biomes {
		var newBiomes:Biomes = new Biomes( _createHeightMap );
		for each ( var layer:LayerInfo in _layers )
			newBiomes.add_layer( layer.clone() );

		return newBiomes;
	}

	public function toString():String {
		var outString:String = "";
		for ( var i:int; i < layers.length; i++ )
		{
			outString += layers[i].toString();
			if ( (i + 1) < layers.length )
				outString += "/n";
		}
		return outString
	}

	// Removed the completed task
	public function addToTaskControllerUsingNewStyle( $guid:String ):void {
		// land task controller
		Globals.g_landscapeTaskController.paused = true

		// Create task group
		var taskGroup:TaskGroup = new TaskGroup("Generate Model for " + $guid, 2);

		// This loads the tasks into the LandscapeTaskQueue
		var task:ITask;
		var layer:LayerInfo
		for ( var i:int; i < layers.length; i++ )
		{
			layer = layers[i];
			// instanceInfo can override type
			//if ( -1 != $ii.type )
				//layer.type = $ii.type;
			//if ( -1 != $ii.grainSize )
				//layer.offset = $ii.grainSize;
			//if ( -1 != $ii.detailSize )
				//layer.range = $ii.detailSize;
			//if ( $ii.controllingModel )
				//layer.optionalString = $ii.topmostGuid();

			task = new layer.task( $guid, layer );
			//Log.out( "Biomes.add_to_task_controller - creating task: " + layer.task );
			taskGroup.addTask(task);
			task = null;
			// If this is loading data leave it along, otherwise erase the layer once it is used.
			if ( layer.functionName && ( ( layer.functionName != "LoadModelFromIVM" ) ) )
				layers[i] = null;
		}

		// remove generation layers
		var newLayers:Vector.<LayerInfo> = new Vector.<LayerInfo>;
		for each ( var layer1:LayerInfo in layers )
		{
			if ( null != layer1 ) {
				newLayers.push( layer1 );
			}
		}
		_layers = null;
		_layers = newLayers;

		//task =  new OutlineBoundries( $guid, null );
		//taskGroup.addTask(task);

		Globals.g_landscapeTaskController.addTask( taskGroup );

		// This unblocks the landscape task controller when all terrain tasks have been added
		Globals.g_landscapeTaskController.paused = false
	}

	public function addParticleTaskToController( $vm:VoxelModel ):void  {
		Globals.g_landscapeTaskController.paused = true
		var guid:String = $vm.instanceInfo.instanceGuid;

		// Create task group
		var taskGroup:TaskGroup = new TaskGroup("addParticleTaskToController: " + guid, 15);
		// This loads the tasks into the LandscapeTaskQueue
		var task:ITask = new ParticleLoadingTask( $vm );
		taskGroup.addTask(task);

		Globals.g_landscapeTaskController.addTask( taskGroup );
		Globals.g_landscapeTaskController.paused = false
	}


	public function	layersLoad( layers:Object):void {
		for each ( var layer:Object in layers ) {
			if ( layer ) {
				var layerInfo:LayerInfo = new LayerInfo();
				layerInfo.fromJSON( layer );
				add_layer( layerInfo );
				//Log.out( "Biomes.load_biomes_data - layer data: " + layerInfo.toString() );
			}
		}
	}

	public function add_layer( li:LayerInfo ):void {
		_layers.push( li );
	}
}

}