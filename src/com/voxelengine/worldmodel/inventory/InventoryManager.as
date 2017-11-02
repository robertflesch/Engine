/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.CharacterSlotEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * The inventory manager is a static object that hold the inventory of different objects
	 * It also acts as the event dispatcher for InventoryEvents
	 * @author Bob
	 */
	
	 
public class InventoryManager
{
	// There is still some confusion here, do I use network id? that would mean only avatars can have inventory
	// really I want any model to be able to have inventory. so this is instanceInfo.instanceGuid.
	static private var  _s_inventoryByGuid:Object = {};
	
	static public function init():void {
		// This creates a inventory object for login.
		InventoryEvent.addListener( InventoryEvent.UNLOAD_REQUEST, unloadInventory );
		InventoryEvent.addListener( InventoryEvent.REQUEST, requestInventory );
        InventoryEvent.addListener( InventoryEvent.REQUEST_NPC, requestInventoryNPC );
//		InventoryEvent.addListener( InventoryEvent.SAVE_REQUEST, save );
//		InventoryEvent.addListener( InventoryEvent.SAVE_FORCE, saveForce );
		InventoryEvent.addListener( InventoryEvent.DELETE, deleteInventory );
		CharacterSlotEvent.addListener( CharacterSlotEvent.CHANGE, characterSlotChange );
        CharacterSlotEvent.addListener( CharacterSlotEvent.REQUEST, characterSlotRequest );

	}

    static public function addModelToInstance( $ownerGuid:String, $slotName:String, $modelGuid:String ):void {
        var ownerModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( $ownerGuid );
        if ( ownerModel ) {
            var attachToModel:VoxelModel = ownerModel.modelInfo.childModelFindByName( $slotName );
            if ( attachToModel ) {
                ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, metadataLoadedForAttachment );
                ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, metadataLoadedForAttachment );
                ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, $modelGuid, null );
            }
            else {
                Log.out( "InventoryManager.addModelToModel - attachmentModel not found guid: " + $slotName );
            }
        } else {
                Log.out( "InventoryManager.addModelToModel - ownerModel not found guid: " + $ownerGuid );
        }

        function metadataLoadedForAttachment( $mde:ModelMetadataEvent ):void {
            ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, metadataLoadedForAttachment );
            ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, metadataLoadedForAttachment );
            var ii:InstanceInfo = new InstanceInfo();
            ii.controllingModel = attachToModel;
            ii.dynamicObject = true;
            ii.rotationSetComp(90, 0, 0);
            var oxelSize:int = $mde.modelMetadata.bound;
            oxelSize = (1 << oxelSize)/2;
            ii.positionSetComp(0, -oxelSize, -oxelSize);
            ii.modelGuid = $modelGuid;
			new ModelMaker( ii );
        }

    }

    static private function characterSlotRequest( $cse:CharacterSlotEvent ): void {
        if ( Globals.online ) {
            var inv:Inventory = _s_inventoryByGuid[$cse.owner];
            if ( null != inv ){
                CharacterSlotEvent.create(CharacterSlotEvent.RESULT,$cse.owner,$cse.slot, inv.characterSlotGet($cse.slot));
            }  else {
                throw new Error( "InventoryManager.characterSlotRequest - inventory NOT found for guid " + $cse.owner );
            }
        }
    }


    static private function characterSlotChange( $cse:CharacterSlotEvent ): void {
		if ( Globals.online ) {
			var inv:Inventory = _s_inventoryByGuid[$cse.owner];
			if ( null != inv ){
                addModelToInstance( $cse.owner, $cse.slot, $cse.guid );
			}  else {
				throw new Error( "InventoryManager.characterSlotChange - inventory NOT found for guid " + $cse.owner );
			}
		}
	}

//	static private function save( e:InventoryEvent ):void {
//		if ( Globals.online ) {
//			if ( null == _s_inventoryByGuid[e.owner] && null != e.result )
//				_s_inventoryByGuid[e.owner] = e.result as Inventory;
//
//			var inv:Inventory = _s_inventoryByGuid[e.owner];
////			if ( null != inv ) {
////				inv.save();
////			}
//
////			for each ( var inventory:Inventory in _s_inventoryByGuid )
////				if ( null != inventory && inventory.guid != "Player" )
////					inventory.save();
//		}
//	}
//
//	static private function saveForce( e:InventoryEvent ):void {
//		if ( Globals.online ) {
//			if ( null == _s_inventoryByGuid[e.owner] && null != e.result )
//				_s_inventoryByGuid[e.owner] = e.result as Inventory;
//
//			var inv:Inventory = _s_inventoryByGuid[e.owner];
////			if ( null != inv ) {
////				inv.changed = true;
////				inv.save();
////			}
//		}
//	}
//
	static private function requestInventory(e:InventoryEvent):void 
	{
		Log.out( "InventoryManager.requestInventory - OWNER: " + e.owner );
		if ( e.owner == "Player" )
			return;
		var inv:Inventory = objectInventoryGet( e );
		if ( inv && inv.loaded ) {
			Log.out( "InventoryManager.requestInventory - InventoryEvent.RESPONSE - OWNER: " + e.owner );
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, e.owner, inv ) );
		}
	}

	static private function requestInventoryNPC(e:InventoryEvent):void
	{
		Log.out( "InventoryManager.requestInventoryNPC - OWNER: " + e.owner );
		if ( e.owner == "Player" )
			return;
		var inv:Inventory = objectInventoryGet( e );
		if ( inv && inv.loaded ) {
			Log.out( "InventoryManager.requestInventoryNPC - InventoryEvent.RESPONSE - OWNER: " + e.owner );
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, e.owner, inv ) );
		}
	}

    static private function deleteInventory(e:InventoryEvent):void
	{
		var inv:Inventory = _s_inventoryByGuid[e.owner];
		if ( inv ) {
			Log.out( "InventoryManager.deleteInventory - InventoryEvent.DELETE - OWNER: " + e.owner, Log.DEBUG );
			inv.deleteInventory();
			_s_inventoryByGuid[e.owner] = null;
		}
	}
	
	static private function unloadInventory(e:InventoryEvent):void 
	{
		var inventory:Inventory = _s_inventoryByGuid[ e.owner ];
		if ( inventory ) {
			var tempArray:Array = [];
			for each ( var inv:Inventory in _s_inventoryByGuid )
			{
				if ( e.owner == inv.ownerGuid ) {
					_s_inventoryByGuid[ e.owner ] = null;
					inv.unload();
					// could I just use a delete here, rather then creating new dictionary? See Dictionary class for details - RSF
				}
				else
				{
					if ( inv )
						tempArray[inv.ownerGuid] = inv;
					else
						Log.out( "InventoryManager.unloadInventory - Null found", Log.ERROR );
				}
			}
			_s_inventoryByGuid = null;
			_s_inventoryByGuid = tempArray;	
		}
	}
	
	static private function objectInventoryGet( $ie:InventoryEvent):Inventory {
		var inventory:Inventory = _s_inventoryByGuid[$ie.owner];
		if ( null == inventory && null != $ie.owner ) {
			//Log.out( "InventoryManager.objectInventoryGet building inventory object for: " + $ownerGuid , Log.WARN );
			inventory = new Inventory( $ie );
			_s_inventoryByGuid[$ie.owner] = inventory;
			//inventory.load();
		}
		
		return inventory;	
	}
}
}
