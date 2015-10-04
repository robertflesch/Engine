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

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerClone extends ModelMakerBase {
	
	private var _oldVM:VoxelModel
		
	public function ModelMakerClone( $vm:VoxelModel ) {
		_oldVM = $vm
		super( _oldVM.instanceInfo.clone(), false )
		Log.out( "ModelMakerClone - ii: " + ii.toString() )
		ii.modelGuid = Globals.getUID()
		
		addListeners()
		
		// this causes it to generate a ModelBaseEvent.ADDED event
		_oldVM.modelInfo.clone( ii.modelGuid )
		_oldVM.metadata.clone( ii.modelGuid )
		_oldVM.dead = true
	}

	override protected function addListeners():void {
		super.addListeners()
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retrivedMetadata )		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retrivedMetadata )		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata )		
	}
	
	private function retrivedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			Log.out( "ModelMakerClone.retrivedMetadata - ii: " + ii.toString() )
			_modelMetadata = $mme.modelMetadata
			
			attemptMake()
		}
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		if ( ii.modelGuid == $mme.modelGuid ) {
			markComplete(false)
		}
	}
	
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _modelMetadata && null != _modelInfo ) {
			Log.out( "ModelMakerClone.attemptMake - ii: " + ii.toString() )
			
			var vm:* = make()

			if ( vm ) {
				//vm.metadata.permissions.blueprintGuid = _oldVM.metadata.guid
				vm.stateLock( true, 10000 ) // Lock state so that is had time to load animations
				vm.complete = true
				vm.changed = true
				vm.save()
				Region.currentRegion.modelCache.add( vm )
			}
			
			markComplete( true, vm )
		}
	}
	
	override protected function markComplete( $success:Boolean, vm:VoxelModel = null ):void {
		removeListeners()		
		function removeListeners():void {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retrivedMetadata )		
			ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retrivedMetadata )		
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata )	
		}		
		
		// do this last as it nulls everything.
		super.markComplete( $success, vm )
	}
}	
}