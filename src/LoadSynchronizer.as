/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
	import com.voxelengine.Globals;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.pools.PoolManager;
	import com.voxelengine.worldmodel.ConfigManager;
	import com.voxelengine.worldmodel.RegionManager;
	
	public class LoadSynchronizer 
	{
		private var _complete:Boolean;
		public function LoadSynchronizer( $startingModelToDisplay:String = null ) {
			WindowSplashEvent.addListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) );
			
			Globals.g_regionManager = new RegionManager();
			Globals.g_configManager = new ConfigManager( $startingModelToDisplay );
			new PoolManager();
			_complete = true;
			startApp();
		}
		
		private function onSplashLoaded(e:WindowSplashEvent):void {
			WindowSplashEvent.removeListener( WindowSplashEvent.SPLASH_LOAD_COMPLETE, onSplashLoaded );
			startApp();
		}
		
		private function startApp():void {
			if ( _complete )
				Globals.g_app.readyToGo();
		}
	}
}