/*==============================================================================
Copyright 2011-2015 Robert Flesch
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
	import com.voxelengine.worldmodel.scripts.Script;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.VoxelModel;
	
	public class AutoControlObjectScript extends Script 
	{
		public function AutoControlObjectScript() 
		{
			Globals.g_app.addEventListener( ModelEvent.AVATAR_MODEL_ADDED, onModelEvent, false, 0, true );
		}
		
		public function onModelEvent( $event:ModelEvent ):void 
		{
			if ( $event.type == ModelEvent.AVATAR_MODEL_ADDED )
			{
				if ( $event.instanceGuid == instanceGuid )
				{
					Globals.g_app.removeEventListener( ModelEvent.AVATAR_MODEL_ADDED, onModelEvent );
					if ( Globals.player ) {
						var vm:VoxelModel = Globals.getModelInstance( instanceGuid );
						vm.takeControl( Globals.player );
						Log.out( "AutoControlObjectScript.AutoControlObjectScript player controlling this object: " + vm.metadata.name );
					}
					else {
						Globals.g_app.addEventListener( LoadingEvent.PLAYER_LOAD_COMPLETE, onLoadingPlayerComplete );
						//Globals.g_app.addEventListener( LoadingEvent.LOAD_COMPLETE, onLoadingPlayerComplete );
					}
				}
			}
		}
		
		private function onLoadingPlayerComplete( le:LoadingEvent ):void {
			Globals.g_app.removeEventListener( LoadingEvent.PLAYER_LOAD_COMPLETE, onLoadingPlayerComplete );
			
			var player:VoxelModel = Globals.player;
			if ( !player ) 
				player = Globals.getModelInstance( le.guid );
				
			var vm:VoxelModel = Globals.getModelInstance( instanceGuid );
			if ( player && vm ) {
				vm.takeControl( player );
			}
		}
	}
}