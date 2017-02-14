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
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.biomes.LayerInfo;
/**
 * ...
 * @author Robert Flesch
 */
public class LoadingImageDisplay extends LandscapeTask 
{		
	public function LoadingImageDisplay( $guid:String, $layer:LayerInfo ):void {
		super( $guid, $layer, "LoadingImageDisplay" );
		Log.out( "LoadingImageDisplay" );
	}
	
	override public function start():void {
		super.start() // AbstractTask will send event
		Log.out( "LoadingImageDisplay.start" );
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );						
		super.complete() // AbstractTask will send event
	}
}
}