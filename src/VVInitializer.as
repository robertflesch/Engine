/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package {
	import flash.display.Stage;
	import flash.external.ExternalInterface;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	import com.voxelengine.GUI.VoxelVerseGUI;
	import com.voxelengine.GUI.WindowSplash;
	import com.voxelengine.worldmodel.MouseKeyboardHandler
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.worldmodel.inventory.InventoryManager;
	import com.voxelengine.persistance.Persistance;
	
	public class VVInitializer 
	{
		static public function initialize( $stage:Stage ):void {
			
			Log.out("VVInitializer.initialize", Log.DEBUG );
			//var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent;}")).toLowerCase();			
			
			// expect an exception to be thrown and caught here, the best way I know of to find out of we are in debug or release mode
			try
			{
				var result : Boolean = new Error().getStackTrace().search(/:[0-9]+]$/m) > -1;
				Globals.g_debug = result;
			}
			catch ( error:Error )
			{
				Globals.g_debug = false;
			}
			
			try
			{
				// This doesnt work in chrome, so I need someway to detect chrome and do it differently
				// Globals.appPath = "file:///C:/dev/VVInitializer/resources/bin/";
				var urlPath:String = ExternalInterface.call("window.location.href.toString");
				Log.out( "VVInitializer.initialize - swf loaded from: " + urlPath );
				var index:int = urlPath.indexOf( "index.html" );
				if ( -1 == index )
				{
					index = urlPath.lastIndexOf( "/" );
					var gap:String = urlPath.substr( 0, index + 1 );
					Globals.appPath = gap;
				}
				else {
					//if ( Globals.g_debug ) 
						Globals.appPath = urlPath.substr( 0, index );
				}
				Log.out( "VVInitializer.initialize - set appPath to: " + Globals.appPath, Log.DEBUG );
			}
			catch ( error:Error )
			{
				Log.out("VVInitializer.initialize - ExternalInterface not found, using default location", Log.ERROR, error );
			}
			
			
			Globals.g_renderer.init( $stage );
			// adds handlers for persistance of regions
			Persistance.addEventHandlers();
			
			VoxelVerseGUI.currentInstance.init();
			WindowSplash.init();
			
			// This adds the event handlers
			// Is there a central place to do this?
			ModelMetadataCache.init();
			ModelInfoCache.init();
			ModelDataCache.init();
			// This causes the to load its caches and listeners
			InventoryManager.init();
			MouseKeyboardHandler.init();
			ModelCacheUtils.init();
		}
	}
}