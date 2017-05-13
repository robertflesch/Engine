/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.types.EditCursor;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistence
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerCursor extends ModelMakerBase {
	
	public function ModelMakerCursor( $ii:InstanceInfo, $vmm:ModelMetadata ) {
		Log.out( "ModelMakerCursor.constructor ii: " + $ii.toString(), Log.DEBUG );
		super( $ii );
		_modelMetadata = $vmm;
		_addToRegionWhenComplete = false;
		makerCountIncrement();
		retrieveBaseInfo();
	}
	
	// once the ModelInfo has been retrieved by base class, we can make the object
	override protected function attemptMake():void {
		if ( null != modelInfo ) {
			Log.out( "ModelMakerCursor.attemptMake - ii: " + ii.toString(), Log.DEBUG );
			_vm = make();
			if ( _vm ) {
				EditCursor.currentInstance.objectModelSet( _vm );

				addListeners();
				OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null );
			}
			else
				markComplete( false );
		}

		function oxelBuildComplete($ode:OxelDataEvent):void {
			if ($ode.modelGuid == modelInfo.guid ) {
				removeListeners();
				markComplete( true );
			}
		}

		function oxelBuildFailed($ode:OxelDataEvent):void {
			if ($ode.modelGuid == modelInfo.guid ) {
				removeListeners();
				markComplete( false );
			}

		}
		function addListeners():void {
			OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
			OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
			OxelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
			OxelDataEvent.addListener( ModelBaseEvent.RESULT, oxelBuildComplete );
			OxelDataEvent.addListener( ModelBaseEvent.ADDED, oxelBuildComplete );
		}

		function removeListeners():void {
			OxelDataEvent.removeListener( ModelBaseEvent.ADDED, oxelBuildComplete );
			OxelDataEvent.removeListener( ModelBaseEvent.RESULT, oxelBuildComplete );
			OxelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
		}
	}


	override protected function markComplete( $success:Boolean ):void {
		super.markComplete( $success );
		makerCountDecrement();
	}

}	
}