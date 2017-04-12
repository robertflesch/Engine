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
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.WindowSplashEvent
import com.voxelengine.worldmodel.models.InstanceInfo

/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is the main class of the model makers used to load data from persistance, 
	 * The base class loads the modelInfo (which exists on the disk for imported models),
 	 * this class loads the model metadata and attempts to create the model
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
	
	override protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
		if (ii.modelGuid == $mie.modelGuid ) {
			//Log.out( "ModelMakerBase.retrievedModelInfo - ii: " + _ii.toString(), Log.DEBUG )
			removeListeners();
			_modelInfo = $mie.vmi;
			ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrievedMetadata );
			ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrievedMetadata );
			ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );

			ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null );
		}
	}

	override protected function failedModelInfo( $mie:ModelInfoEvent):void  {
		if ( ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + ii.toString(), Log.WARN );
			removeListeners();
			markComplete( false );
		}
	}

	private function removeListeners():void {
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retrievedModelInfo );
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrievedModelInfo );
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
	}


	private function retrievedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			removeMetadataListeners();
			_modelMetadata = $mme.modelMetadata;
			//Log.out( "ModelMaker.retrivedMetadata - metadata: " + _modelMetadata.toString() )
			attemptMake();
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			removeMetadataListeners();
			markComplete(false);
		}
	}

	private function removeMetadataListeners():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrievedMetadata );
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrievedMetadata );
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata )
	}

	
	// once they both have been retrieved, we can make the object
	override protected function attemptMake():void {
		if ( null != _modelMetadata && null != modelInfo ) {
			//Log.out( "ModelMaker.attemptMake - ii: " + ii.toString() )
			
			_vm = make();
			if ( _vm ) {
				OxelDataEvent.addListener(OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
				OxelDataEvent.addListener(OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
				OxelDataEvent.addListener(ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
				OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null );
			} else {
				markComplete(false);
			}
		}

		function oxelBuildComplete($ode:OxelDataEvent):void {
			if ($ode.modelGuid == modelInfo.guid ) {
				OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
				OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
				OxelDataEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
				markComplete( true );
			}
		}

		function oxelBuildFailed($ode:OxelDataEvent):void {
			if ($ode.modelGuid == modelInfo.guid ) {
				OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
				OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
				OxelDataEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
				markComplete( false );
			}
		}
	}

	override protected function markComplete( $success:Boolean ):void {
		if ( _addToCount ) {
			makerCountDecrement();
			if (0 == makerCountGet())
				WindowSplashEvent.dispatch(new WindowSplashEvent(WindowSplashEvent.ANNIHILATE))
		}

		// do this last as it nulls everything.
		super.markComplete( $success );
	}
}	
}