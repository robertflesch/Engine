/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.makers.ModelLoader;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 * This is actually the perfect task, very small potentially time intensive.
	 */
	public class LoadFromByteArray extends LandscapeTask 
	{		
		public function LoadFromByteArray( $guid:String, $layer:LayerInfo, $taskType:String = "LoadFromByteArray", $taskPriority:int = TASK_PRIORITY ):void {
			//Log.out( "LoadFromByteArray.constructor " );
			_layer = $layer;
			_startTime = getTimer();
			super( $guid, $layer, $taskType, $taskPriority );
			throw new Error( "LoadFromByteArray - not implemented" );
		}
		
		
		override public function start():void
		{
			//super.start() // AbstractTask will send event
			//var timer:int = getTimer();
			//
			//var vm:VoxelModel = getVoxelModel();
			//var ba:ByteArray = Globals.findIVM( _layer.data );
			//if ( vm && ba )		
			//{
				//ModelLoader.loadLocalModelFromByteArray( vm, ba );
			//}
			//else
				//Log.out( "LoadFromByteArray.loadByteArray - FAILED to find either voxel model or byte array: guid: " + _guid + "  data: " + _layer.data , Log.ERROR );
//
			super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
