/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
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
				if ( vm ) {
//					Log.out( "CompletedModel.start - VoxelModel marked as complete: " + _guid );
 					vm.complete = true;
					vm.calculateCenter();

					// This is only called when executing a script or series of scripts on an object
					if ( Globals.online ) {
						throw new Error( "CompletedModel.start - Should not be used" );
					}
						
					if ( vm is Player )
					{
						LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.PLAYER_LOAD_COMPLETE, _instanceGuid ) );
					}
					else {
						if ( vm.instanceInfo.critical )
							LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.CRITICAL_MODEL_LOADED, _instanceGuid ));
						else
							LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _instanceGuid ) );
					}
				}
				else
				{
					Log.out( "CompletedModel.start - VoxelModel Not found: " + _instanceGuid, Log.WARN );
				}
			}
			catch ( error:Error )
			{
				if ( Globals.player.instanceInfo.instanceGuid == _instanceGuid )
					Globals.player.complete = true;
				else
					Log.out( "CompletedModel.start - exception was thrown for model guid: " + _instanceGuid, Log.ERROR );
			}
			
			//Log.out( "CompletedModel.start - completedModel: " + _guid + "  count: " + _count );
				
			if ( 0 == _count  ) // && _playerLoaded  should I add ( null != Globals.player )
			{
				Log.out( "CompletedModel.start - ALL MODELS LOADED - dispatching the LoadingEvent.LOAD_COMPLETE event vm: " + _instanceGuid );
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			}
			
			
			super.complete(); // This MUST be called for tasks to continue
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
