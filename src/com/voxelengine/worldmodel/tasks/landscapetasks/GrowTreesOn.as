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
import com.voxelengine.renderer.Chunk;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.renderTasks.RenderingTask;

public class GrowTreesOn extends RenderingTask
{
	private var _chance:int;
	static public function addTask( $guid:String, $chunk:Chunk, $chance:int ): void {
		Log.out("GrowTreesOn.addTask: guid: " + $guid, Log.WARN);
		new GrowTreesOn( $guid, $chunk, 100, $chance );
	}

	public function GrowTreesOn($guid:String, $chunk:Chunk, $taskPriority:int, $chance:int ):void {
		super( $guid, $chunk, "GrowTreesOn", $taskPriority );
		_chance = $chance;
	}

	override public function start():void {
		super.start();
		Log.out("GrowTreesOn.start: guid: " + _guid  + "  gc: " + _chunk.gc, Log.WARN);

		var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
		if ( _chunk && _chunk.oxel )
			_chunk.oxel.growTreesOn( vm, TypeInfo.GRASS, _chance );
		super.complete();
	}
}
}