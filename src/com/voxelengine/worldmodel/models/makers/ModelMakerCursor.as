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
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerCursor extends ModelMakerBase {
	
	public function ModelMakerCursor( $ii:InstanceInfo, $vmm:ModelMetadata ) {
		Log.out( "ModelMakerCursor.constructor ii: " + $ii.toString(), Log.DEBUG );
		super( $ii );
		_vmm = $vmm;
		if ( 0 == makerCountGet() )
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		makerCountIncrement();
		retrieveBaseInfo();
	}
	
	// once the ModelInfo has been retrieved by base class, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi ) {
			Log.out( "ModelMakerCursor.attemptMake - ii: " + _ii.toString(), Log.DEBUG );
			var vm:* = make();
			if ( vm )
				EditCursor.currentInstance.objectModelSet( vm );
			markComplete();
		}
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete( $success );
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
		}
	}

}	
}