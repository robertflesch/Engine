/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.renderTasks
{
import com.voxelengine.Log;
import com.voxelengine.events.LoadingImageEvent;

public class LoadingImageDisplay extends RenderingTask
{
	static public function addTask( $guid:String ): void {
		new LoadingImageDisplay( $guid );
	}

	public function LoadingImageDisplay( $guid:String ):void {
		super( $guid, null, "LoadingImageDisplay", 1 );
	}
	
	override public function start():void {
		super.start(); // AbstractTask will send event
		Log.out( "LoadingImageDisplay.start" );
		LoadingImageEvent.create( LoadingImageEvent.CREATE );
		super.complete(); // AbstractTask will send event
	}
}
}