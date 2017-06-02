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
	public function get addToCount():Boolean { return _addToCount; }
	public function set addToCount(value:Boolean):void { _addToCount = value; }

	public function ModelMaker( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean = true, $addToCount:Boolean = true ) {
		//Log.out( "ModelMaker.constructor ii: " + $ii.toString(), Log.DEBUG );
		super( $ii );
		addToRegionWhenComplete = $addToRegionWhenComplete;
		addToCount = $addToCount;
		if ( addToCount )
			makerCountIncrement();
		requestModelInfo();
	}
	
	override protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
		if (ii.modelGuid == $mie.modelGuid ) {
			//Log.out( "ModelMakerBase.retrievedModelInfo - ii: " + _ii.toString(), Log.DEBUG )
			removeMIEListeners();
			_modelInfo = $mie.vmi;
			addMetadataListeners();
			ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null );
		}
	}


	
	// once they both have been retrieved, we can make the object
	override protected function attemptMake():void {
		if ( null != _modelMetadata && null != modelInfo ) {
			//Log.out( "ModelMaker.attemptMake - ii: " + ii.toString() )

			_vm = make();
			if ( _vm ) {
				addODEListeners();
				OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null );
			} else {
				markComplete(false);
			}
		}
	}

	override protected function markComplete( $success:Boolean ):void {
		if ( addToCount ) {
			makerCountDecrement();
			if (0 == makerCountGet())
				WindowSplashEvent.create(WindowSplashEvent.ANNIHILATE);
		}

		// do this last as it nulls everything.
		super.markComplete( $success );
	}
}
}