/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import flash.utils.getTimer;
	import flash.geom.Vector3D;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.events.LoadingEvent;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class CompletedModel extends LandscapeTask 
	{		
		static private var _count:int = 0;
		
		public function CompletedModel( instanceGuid:String, layer:LayerInfo, taskType:String = TASK_TYPE, taskPriority:int = TASK_PRIORITY ):void {
//			Log.out( "CompletedModel.construct for guid: " + instanceGuid + "  count: " + _count );
			_startTime = getTimer();
			_count++;
			super( instanceGuid, layer, "CompletedModel" );
		}
		
		override public function start():void
		{
			super.start() // AbstractTask will send event
			_count--;

//			Log.out( "CompletedModel.start - start: " + _guid );
			try
			{
				var vm:VoxelModel = getVoxelModel();
//				var vm:VoxelModel = Globals.getModelInstance( _guid );
				if ( vm ) {
//					Log.out( "CompletedModel.start - VoxelModel marked as complete: " + _guid );
 					vm.complete = true;
					vm.calculateCenter();

					if ( vm is Player )
					{
						Globals.player = vm as Player;
						Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.PLAYER_LOAD_COMPLETE, _guid ) );
					}
					else {
						if ( vm.instanceInfo.critical )
							Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.CRITICAL_MODEL_LOADED, _guid ));
						else
							Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _guid ) );
					}
				}
				else
				{
					Log.out( "CompletedModel.start - VoxelModel Not found: " + _guid, Log.WARN );
				}
			}
			catch ( error:Error )
			{
				if ( Globals.player.instanceInfo.guid == _guid )
					Globals.player.complete = true;
				else
					Log.out( "CompletedModel.start - exception was thrown for model guid: " + _guid, Log.ERROR );
			}
			
			//Log.out( "CompletedModel.start - completedModel: " + _guid + "  count: " + _count );
				
			if ( 0 == _count  ) // && _playerLoaded  should I add ( null != Globals.player )
			{
				Log.out( "CompletedModel.start - ALL MODELS LOADED - dispatching the LoadingEvent.LOAD_COMPLETE event vm: " + _guid );
				Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			}
			
			super.complete(); // This MUST be called for tasks to continue
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
