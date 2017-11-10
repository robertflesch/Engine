/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers {

import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to delete and its children a model from persistence
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelDestroyer {
	
	private var _modelGuid:String;
	private var _recursive:Boolean;
	
	public function ModelDestroyer( $modelGuid:String, $recursive:Boolean ) {
        _modelGuid = $modelGuid;
        _recursive = $recursive;

        // The Region could also listen for model delete
        // this removes the on screen instances
        var modelOnScreen:Vector.<VoxelModel> = Region.currentRegion.modelCache.instancesOfModelGet(_modelGuid);
        // only instances have inventory, not models
        for each (var vm:VoxelModel in modelOnScreen)
            vm.dead = true;

        Log.out("ModelDestroyer - removing modelGuid: " + _modelGuid + ( _recursive ? " and children from" : " from" ) + " persistance");

        // We need to do metadata first so that we can check permissions
		addModelMetadataListeners();
        ModelMetadataEvent.create(ModelBaseEvent.REQUEST, 0, _modelGuid, null);

        function metaDataResultFailed($mmd:ModelMetadataEvent):void {
            if (_modelGuid == $mmd.modelGuid) {
                removeModelMetadataListeners();
                Log.out("ModelDestroyer.metaDataResultFailed - failed to find modelMetadata guid: " + _modelGuid, Log.WARN);
            }
        }

        function metaDataResult( $mmd:ModelMetadataEvent ):void {
            if (_modelGuid == $mmd.modelGuid ) {
                removeModelMetadataListeners();
                if ( $mmd.modelMetadata.owner == Network.PUBLIC && Player.player.role.modelPublicDelete )
                    permissionsVerified();
                else if ( $mmd.modelMetadata.owner == Network.userId )
                    permissionsVerified();
                else
                    Log.out("ModelDestroyer.metaDataResult - permission failure for modelMetadata guid: " + _modelGuid + " aborting -- owner: " + $mmd.modelMetadata.owner + " deleting users role: " + Player.player.role.name, Log.WARN);
            }
        }

        function removeModelMetadataListeners():void {
            ModelMetadataEvent.removeListener(ModelBaseEvent.RESULT, metaDataResult);
            ModelMetadataEvent.removeListener(ModelBaseEvent.ADDED, metaDataResult);
            ModelMetadataEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, metaDataResultFailed);
        }

        function addModelMetadataListeners():void {
            ModelMetadataEvent.addListener(ModelBaseEvent.RESULT, metaDataResult);
            ModelMetadataEvent.addListener(ModelBaseEvent.ADDED, metaDataResult);
            ModelMetadataEvent.addListener(ModelBaseEvent.REQUEST_FAILED, metaDataResultFailed);
        }
    }

    private function permissionsVerified():void {
        // request the modelInfo so that we can get the children from it.
        ModelInfoEvent.addListener( ModelBaseEvent.RESULT, dataResult );
        ModelInfoEvent.addListener( ModelBaseEvent.ADDED, dataResult );
        ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _modelGuid, null );

        function dataResult( $mie:ModelInfoEvent):void	{
            if ( _modelGuid == $mie.modelGuid ) {
                //Log.out( "ModelDestroyer.dataResult - received modelInfo: " + $mie, Log.WARN );
                // Now that we have the modelData, we can extract the modelInfo
                removeListeners();

                // now have the modelData to remove all of the guids associated with this model.
                removeTheRest( $mie.vmi );

                // Let MetadataCache handle the recursive delete
                if ( _recursive )
                    ModelInfoEvent.create( ModelInfoEvent.DELETE_RECURSIVE, 0, _modelGuid, null, _recursive );
                else
                    ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, _modelGuid, null );

            }
        }

        function dataResultFailed( $mie:ModelInfoEvent):void {
            if ( _modelGuid == $mie.modelGuid ) {
                removeListeners();
                Log.out( "ModelDestroyer.dataResultFailed - failed to receive modelInfo: " + _modelGuid + " but continuing", Log.WARN );
                removeTheRest( null );
            }
        }

        function removeListeners():void {
            ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, dataResult);
            ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, dataResult);
        }
	}

    private function removeTheRest( $mi:ModelInfo ):void {
        if ( $mi ) {
            $mi.animationsDelete();
        }
		ModelMetadataEvent.create(ModelBaseEvent.DELETE, 0, _modelGuid, null);
		OxelDataEvent.create(ModelBaseEvent.DELETE, 0, _modelGuid, null);
        // TODO Remove sounds! RSF
		// TODO Inventory is by instance... but this is removing the model template.
		// InventoryModelEvent.dispatch( new InventoryModelEvent( ModelBaseEvent.DELETE, "", vm.instanceInfo.instanceGuid, null ) )
	}
}
}