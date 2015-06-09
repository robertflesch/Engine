/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.ModelMetadata;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its model AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerLocal extends ModelMakerBase {
	
	public function ModelMakerLocal( $ii:InstanceInfo ) {
		//Log.out( "ModelMakerLocal ii.modelGuid: " + $ii.modelGuid, Log.WARN );
		super( $ii, false );
		// keeps track of how many makers there currently are.
		makerCountIncrement();
		retrieveBaseInfo();
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi ) {
			var vmm:ModelMetadata = new ModelMetadata( _ii.modelGuid );
			vmm.name = _vmi.fileName;
			vmm.description = _vmi.fileName + " from local data";
			var vm:* = make();
			if ( vm )
				Region.currentRegion.modelCache.add( vm );
			
			markComplete( true, vm );
		}
	}
	
	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		super.markComplete( $success, $vm );
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			//Log.out( "ModelMakerLocal.markComplete - makerCount: 0, SHUTTING DOWN SPLASH", Log.WARN );
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
	}
}	
}