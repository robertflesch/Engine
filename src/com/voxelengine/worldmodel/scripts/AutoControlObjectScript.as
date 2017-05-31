/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.scripts 
{
	/**
	 * ...
	 * @author Bob
	 */
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.OxelDataEvent;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.scripts.Script;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	public class AutoControlObjectScript extends Script 
	{
		public function AutoControlObjectScript( $params:Object ) {
			super ( $params );
			ModelEvent.addListener( ModelEvent.AVATAR_MODEL_ADDED, onModelEvent, false, 0, true );
			Log.out( "AutoControlObjectScript.AutoControlObjectScript scirpt for player controlling this object: ", Log.ERROR );
		}
		
		public function onModelEvent( $event:ModelEvent ):void 
		{
			if ( $event.instanceGuid == instanceGuid )
			{
				ModelEvent.removeListener( ModelEvent.AVATAR_MODEL_ADDED, onModelEvent );
				if ( Player.player ) {
					var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( instanceGuid );
					vm.takeControl( VoxelModel.controlledModel );
					Log.out( "AutoControlObjectScript.AutoControlObjectScript player controlling this object: " + vm.metadata.name );
				}
				else {
					OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, onOxelBuildComplete )
					
					//LoadingEvent.addListener( LoadingEvent.PLAYER_LOAD_COMPLETE, onLoadingPlayerComplete );
				}
			}
		}
		
		private function onOxelBuildComplete( $ode:OxelDataEvent ):void {
			if ( $ode.modelGuid == VoxelModel.controlledModel.modelInfo.guid ) {
				OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_COMPLETE, onOxelBuildComplete )
				var player:VoxelModel = VoxelModel.controlledModel;
				var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( instanceGuid );
				if ( player && vm ) {
					vm.takeControl( player );
				}
			}
			//LoadingEvent.removeListener( LoadingEvent.PLAYER_LOAD_COMPLETE, onLoadingPlayerComplete );
			
		}
	}
}