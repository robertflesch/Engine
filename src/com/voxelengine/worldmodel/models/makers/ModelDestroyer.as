/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to delete a model from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelDestroyer {
	
	private var _modelGuid:String;
	private var _recursive:Boolean;
	
	public function ModelDestroyer( $modelguid:String, $recursive:Boolean ) {
		
		_modelGuid = $modelguid;
		_recursive = $recursive;
		Log.out( "ModelDestroyer - removing modelGuid: " + _modelGuid + ( _recursive ? " and children from" : " from" ) + " persistance" );
		
		// remove inventory
		// request the ModelData so that we can get the modelInfo from it.
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, dataResult );
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, dataResult );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) );

		// this removes the on screen instances
		var modelOnScreen:Vector.<VoxelModel> = Region.currentRegion.modelCache.modelGet( _modelGuid );
		// only instances have inventory, not models
		for each ( var vm:VoxelModel in modelOnScreen ) {
			vm.dead = true;
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.DELETE, vm.instanceInfo.instanceGuid, null ) );
		}
	}
	
	private function dataResult(e:ModelInfoEvent):void 
	{
		// Now that we have the modelData, we can extract the modelInfo
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, dataResult );
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, dataResult );
		
		// now tell the modelData to remove all of the guids associated with this model.
		if ( e.vmi )
			e.vmi.animationsDelete();

		// Let MetadataCache handle the recursive delete
		if ( _recursive )
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.DELETE_RECURSIVE, 0, _modelGuid, null ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.DELETE, 0, _modelGuid, null ) );
		
	}
}	
}