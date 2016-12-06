/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.worldmodel.Region
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.models.ModelMetadata
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.GrainCursorUtils;

import flash.geom.Vector3D;

/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerClone extends ModelMakerBase {
	
	private var _oldVM:VoxelModel
		
	public function ModelMakerClone( $vm:VoxelModel, $killOldModel:Boolean = true ) {
		_oldVM = $vm;
		super( _oldVM.instanceInfo.clone(), false );
		ii.modelGuid = Globals.getUID();
		if ( $killOldModel ) {
			_oldVM.dead = true;
		} else {

			var size:int = GrainCursor.two_to_the_g( $vm.modelInfo.data.oxel.gc.grain );
			var offset:Vector3D = new Vector3D(1,1,1);
			offset.scaleBy(size);
			var v:Vector3D = ii.positionGet.clone();
			v = v.add( offset );
			ii.positionSetComp( v.x, v.y, v.z  );
		}
		Log.out( "ModelMakerClone - ii: " + ii.toString() );

		addListeners();
		
		// this causes it to generate a ModelBaseEvent.ADDED event
		_oldVM.modelInfo.clone( ii.modelGuid );
		_oldVM.metadata.clone( ii.modelGuid );
	}

	override protected function addListeners():void {
		super.addListeners()
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );
	}
	
	private function retrivedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			Log.out( "ModelMakerClone.retrivedMetadata - ii: " + ii.toString() );
			_modelMetadata = $mme.modelMetadata;
			
			attemptMake()
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
			Log.out( "ModelMakerClone.attemptMake - ii: " + ii.toString() );
			
			var vm:* = make();

			if ( vm ) {
				//vm.metadata.permissions.blueprintGuid = _oldVM.metadata.guid
				vm.stateLock( true, 10000 ); // Lock state so that is had time to load animations
				vm.complete = true;
				vm.changed = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			
			markComplete( true, vm );
		}
	}
	
	override protected function markComplete( $success:Boolean, vm:VoxelModel = null ):void {
		removeListeners();
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