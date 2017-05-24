/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.renderTasks {
import com.voxelengine.Log;
import com.voxelengine.events.LoadingImageEvent;

public class LoadingImageDestroy extends RenderingTask {
	static public function addTask( $guid:String ): void {
		new LoadingImageDestroy( $guid );
	}

	public function LoadingImageDestroy( $guid:String ):void {
		super( $guid, null, "LoadingImageDisplay", 1 );
	}

	override public function start():void {
		super.start();
		Log.out( "LoadingImageDestroy.start" );
		LoadingImageEvent.create( LoadingImageEvent.DESTROY );
		super.complete();
	}
}
}