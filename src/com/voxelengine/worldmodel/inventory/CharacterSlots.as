/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under uinted States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.inventory {
import com.voxelengine.Log;
import com.voxelengine.events.CharacterSlotEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelLoadingEvent;

public class CharacterSlots {

    private var _owner:Inventory;
    private var _items:Object = {};
    public function get items():Object { return _items; }
    private var _itemCount:int;
    private const ITEM_COUNT:int = 2;

    public function CharacterSlots($owner:Inventory) {
        CharacterSlotEvent.addListener(CharacterSlotEvent.CHANGE, slotChange);
        _owner = $owner;
    }

    public function slotChange($cse:CharacterSlotEvent):void {
        Log.out("CharacterSlots.slotChange slot: " + $cse.slot + "  item: " + $cse.guid);
        if (_owner.ownerGuid == $cse.owner) {
            if (null == $cse.guid)
                setItemData($cse.slot, "");
            else
                setItemData($cse.slot, $cse.guid);
            _owner.changed = true;
            InventoryEvent.create( InventoryEvent.SAVE_REQUEST, _owner.ownerGuid, null );
        }
    }

    public function addDefaultData():void {
        Log.out( "CharacterSlots.addDefaultData", Log.WARN );
    }

    static private function createObjectFromInventoryString($data:String, $slotId:int):ObjectInfo {
        // find the first comma so we can get the substring with the object type
        var type:int = int($data.charAt(0));
        if (type == 1)
            return new ObjectInfo(null, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME);
        else if (type == 2)
            return new ObjectVoxel(null, 0).fromInventoryString($data, $slotId);
        else if (type == 3)
            return new ObjectModel(null, "").fromInventoryString($data, $slotId);
        else if (type == 4)
            return new ObjectAction(null, "", "", "").fromInventoryString($data, $slotId);
        else if (type == 5)
            return new ObjectGrain(null, "", "").fromInventoryString($data, $slotId);
        else if (type == 6)
            return new ObjectTool(null, "", "", "", "").fromInventoryString($data, $slotId);
        else
            Log.out("CharacterSlots.createObjectFromInventoryString - type: " + type + "  NOT FOUND", Log.ERROR);

        return new ObjectInfo(null, ObjectInfo.OBJECTINFO_INVALID, ObjectInfo.DEFAULT_OBJECT_NAME);
    }

    /*
     public function addSlotDefaultData():void {
     Log.out( "CharacterSlots.addSlotDefaultData", Log.WARN );
     initializeCharacterSlots();

     // is guid model OR instance?
     // its the MODEL guid, since models have default oxelPersistence, instances have specific oxelPersistence
     // so this message is handle by the model class.
     // might need to be a table driven event also.
     // so the default oxelPersistence is in the "class inventory" table
     _owner.loaded = true;
     CharacterSlotEvent.create( CharacterSlotEvent.DEFAULT_REQUEST, _owner.guid, 0, "" );
     }
     */
    public function fromObject($info:Object):void {
        _itemCount = 0;
        if ($info && $info.characterSlots) {
            for (var slotName:String in $info.characterSlots) {
                _items[slotName] = $info.characterSlots[slotName];
                if ( 0 == _itemCount ) {
                    ModelLoadingEvent.addListener(ModelLoadingEvent.CHILD_LOADING_COMPLETE, modelChildLoadComplete);
                    ModelLoadingEvent.addListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
                }
                _itemCount++;
            }
        }
    }

    private function modelLoadComplete($mle:ModelLoadingEvent):void {
        if ( $mle.vm ) {
            if ( loadAttachmentForThisModelName( $mle.vm.modelInfo.name ) )
                if ( 0 == _itemCount ){
                    ModelLoadingEvent.removeListener(ModelLoadingEvent.CHILD_LOADING_COMPLETE, modelChildLoadComplete);
                    ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
                }
        }
    }

    private function modelChildLoadComplete($mle:ModelLoadingEvent):void {
        if ( $mle.vm ) {
            if ( loadAttachmentForThisModelName( $mle.vm.modelInfo.name ) ) {
                if ( 0 == _itemCount ){
                    ModelLoadingEvent.removeListener(ModelLoadingEvent.CHILD_LOADING_COMPLETE, modelChildLoadComplete);
                    ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
                }
            }
        }
    }

    private function loadAttachmentForThisModelName( $metaDataName:String ):Boolean {
        for ( var slotName:String in _items ) {
            if (null != _items[slotName]) {
                if ($metaDataName == slotName) {
                    InventoryManager.addModelToInstance(_owner.ownerGuid, slotName, _items[slotName]);
                    _itemCount--;
                    return true;
                }
            }
        }
        return false;
    }

//    public function loadCharacterInventory():void {
//        for ( var slotName:String in _items ) {
//            InventoryManager.addModelToInstance( _owner.guid, slotName, _items[slotName] );
//        }
//    }

    public function toObject( $info:Object ):void {
        $info.characterSlots = {};
        for ( var slotName:String in _items ) {
            if (  null != _items[slotName] )
                $info.characterSlots[slotName]	= _items[slotName];
        }
    }

    private function setItemData( $slot:String, $guid:String ):void {
        _items[$slot] = $guid;
    }

    public function unload():void {}

}
}
