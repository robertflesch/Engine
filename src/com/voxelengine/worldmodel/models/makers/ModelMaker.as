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
//import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is the main class of the model makers used to load data from persistance, 
	 * ModelMakers are temporary objects which go away after the model has loaded or failed.
	 */
public class ModelMaker extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	private var _addToRegionWhenComplete:Boolean;
	
	public function ModelMaker( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean ) {
		Log.out( "ModelMaker.constructor ii: " + $ii.toString(), Log.DEBUG );
		super( $ii );
		_addToRegionWhenComplete = $addToRegionWhenComplete;
		if ( 0 == makerCountGet() )
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		makerCountIncrement();
		retrieveBaseInfo();
	}
	
	override protected function retrieveBaseInfo():void {
		super.retrieveBaseInfo();
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
	
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			markComplete(false);
		}
	}
	
	private function retrivedMetadata( $mme:ModelMetadataEvent):void {
		if ( _ii.modelGuid == $mme.modelGuid ) {
			Log.out( "ModelMaker.retrivedMetadata - ii: " + _ii.toString() );
			_vmm = $mme.vmm;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmm && null != _vmi ) {
			Log.out( "ModelMaker.attemptMake - ii: " + _ii.toString() );
			
			var vm:* = make();
			
			markComplete( true, vm );
			if ( vm && _addToRegionWhenComplete )
				Region.currentRegion.modelCache.add( vm );
		}
	}
	
	override protected function markComplete( $success:Boolean, vm:VoxelModel = null ):void {
		removeListeners();		
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			//Log.out( "ModelMaker.markComplete - makerCount: 0, SHUTTING DOWN SPLASH", Log.WARN );
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
		
		function removeListeners():void {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrivedMetadata );		
			ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrivedMetadata );		
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );	
		}		
		
		// do this last as it nulls everything.
		super.markComplete( $success, vm );
	}
}	
}