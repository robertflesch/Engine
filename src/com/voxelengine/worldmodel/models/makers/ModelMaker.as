/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.WindowSplashEvent
import com.voxelengine.worldmodel.Region
import com.voxelengine.worldmodel.models.InstanceInfo
import com.voxelengine.worldmodel.models.makers.ModelMakerBase
import com.voxelengine.worldmodel.models.types.VoxelModel

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is the main class of the model makers used to load data from persistance, 
	 * The base class loads the modelInfo, this class loads the model metadata
	 * when both are non null, the voxel model is created.
	 * ModelMakers are temporary objects which go away after the model has loaded or failed.
	 */
public class ModelMaker extends ModelMakerBase {
	
	private var		_addToCount:Boolean;
	
	public function ModelMaker( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean, $addToCount:Boolean = true ) {
		//Log.out( "ModelMaker.constructor ii: " + $ii.toString(), Log.DEBUG );
		super( $ii );
		_addToRegionWhenComplete = $addToRegionWhenComplete;
		_addToCount = $addToCount;
		if ( _addToCount )
			makerCountIncrement();
		retrieveBaseInfo();
	}
	
	override protected function retrieveBaseInfo():void {
		super.retrieveBaseInfo();
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );
	
		ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null );
	}
	
	private function retrivedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			_modelMetadata = $mme.modelMetadata;
			//Log.out( "ModelMaker.retrivedMetadata - metadata: " + _modelMetadata.toString() )
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			markComplete(false);
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _modelMetadata && null != modelInfo ) {
			//Log.out( "ModelMaker.attemptMake - ii: " + ii.toString() )
			
			_vm = make();
			markComplete( true )
		}
	}
	
	override protected function markComplete( $success:Boolean ):void {
		if ( _addToCount ) {
			makerCountDecrement();
			if (0 == makerCountGet())
				WindowSplashEvent.dispatch(new WindowSplashEvent(WindowSplashEvent.ANNIHILATE))
		}
		removeListeners();
		
		// do this last as it nulls everything.
		super.markComplete( $success );
		
		function removeListeners():void {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrivedMetadata );
			ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrivedMetadata );
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata )	
		}		
		
	}
}	
}