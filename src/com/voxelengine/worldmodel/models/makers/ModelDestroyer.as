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
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
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
	
	public function ModelDestroyer( $modelGuid:String, $recursive:Boolean ) {
        // The Region could also listen for model delete
        // this removes the on screen instances
        var modelOnScreen:Vector.<VoxelModel> = Region.currentRegion.modelCache.instancesOfModelGet($modelGuid);
        // only instances have inventory, not models
        for each (var vm:VoxelModel in modelOnScreen)
            vm.dead = true;

        Log.out("ModelDestroyer - attempting to remove modelGuid: " + $modelGuid + ( $recursive ? " and children from" : " from" ) + " persistence", Log.WARN);

        addListeners();
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, $modelGuid, null );

        function dataResult( $mie:ModelInfoEvent):void {
            if ( $modelGuid == $mie.modelGuid ) {
                removeListeners();
                if (  ( $mie.modelInfo.owner == Network.PUBLIC && Player.player.role.modelPublicDelete )
                   || ( $mie.modelInfo.owner == Network.userId ) ) {

                    if ($mie.modelInfo)
                        $mie.modelInfo.animationsDelete();

                    // This has to be last since it destroys the modelInfo
                    if ($recursive)
                        ModelInfoEvent.create(ModelInfoEvent.DELETE_RECURSIVE, 0, $modelGuid, null, $recursive);
                    else
                        ModelInfoEvent.create(ModelBaseEvent.DELETE, 0, $modelGuid, null);

                    OxelDataEvent.create(ModelBaseEvent.DELETE, 0, $modelGuid, null);
                    // TODO Remove sounds! RSF
                    // TODO Inventory is by instance... but this is removing the model template.
                    // InventoryModelEvent.dispatch( new InventoryModelEvent( ModelBaseEvent.DELETE, "", vm.instanceInfo.instanceGuid, null ) )
                }
                Log.out("ModelDestroyer - SUCCESSFULLY removed modelGuid: " + $modelGuid + ( $recursive ? " and children from" : " from" ) + " persistence", Log.WARN);
            }
        }

        function dataResultFailed( $mie:ModelInfoEvent):void {
            if ( $modelGuid == $mie.modelGuid ) {
                removeListeners();
                Log.out( "ModelDestroyer.dataResultFailed - failed to receive modelInfo: " + $modelGuid + " but continuing", Log.WARN );
            }
        }

        function addListeners():void {
            ModelInfoEvent.addListener( ModelBaseEvent.RESULT, dataResult );
            ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );
        }

        function removeListeners():void {
            ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, dataResult);
            ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );
        }
    }
}
}