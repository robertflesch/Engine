/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {

import com.voxelengine.Log;
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.events.InventorySlotEvent;

public class Slots
{
	static public const ITEM_COUNT:int = 10;
	
	private var _items:Vector.<ObjectInfo> = new Vector.<ObjectInfo>(10, true);
	private var _owner:Inventory;
	public function get items():Vector.<ObjectInfo>  { return _items; }

	public function Slots( $owner:Inventory ) {
		// Do I need to unregister this?
		InventorySlotEvent.addListener( InventorySlotEvent.CHANGE,	slotChange );
		//InventorySlotEvent.addListener( InventorySlotEvent.DEFAULT_RESPONSE, defaultResponse );
		_owner = $owner;
		FunctionRegistry.functionAdd( noneSlots, "noneSlots" );
		FunctionRegistry.functionAdd( pickToolSlots, "pickToolSlots" );
	}
/*	
	private function defaultResponse(e:InventorySlotEvent):void {
		
		var defaultSlotData:Vector.<ObjectInfo> = e.data as Vector.<ObjectInfo>;
		
		
		Log.out( "Slots.addSlotDefaultData - Loading default data into slots" , Log.WARN );
		for ( var i:int; i < Slots.ITEM_COUNT; i++ )
			setItemData( i, defaultSlotData[i] );

		changed = true;
		
	}
	*/
	public function unload():void {
		InventorySlotEvent.removeListener( InventorySlotEvent.CHANGE,	slotChange );
	}
	
	public function slotChange(e:InventorySlotEvent):void {
		Log.out( "Slots.slotChange slot: " + e.slotId + "  item: " + e.data );
		if ( _owner.guid == e.ownerGuid ) {
			if ( _items ) {
				if ( null == e.data )
					setItemData( e.slotId, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) );
				else
					setItemData( e.slotId, e.data );
				_owner.changed = true;
			}
			else
				Log.out( "Slots.slotChange _slots container not initialized", Log.WARN );

			//_owner.save();
		}
	}
	
	private function createObjectFromInventoryString( $data:String, $slotId:int ):ObjectInfo {
		// find the first comma so we can get the substring with the object type
		var type:int = int( $data.charAt(0) );
		if ( type == 1 )
			return new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY );		
		else if ( type == 2 )
			return new ObjectVoxel( null, 0 ).fromInventoryString( $data, $slotId ); 
		else if ( type == 3 )
			return new ObjectModel( null, "" ).fromInventoryString( $data, $slotId );
		else if ( type == 4 )
			return new ObjectAction( null, "", "", "" ).fromInventoryString( $data, $slotId );
		else if ( type == 5 )
			return new ObjectGrain( null, "", "" ).fromInventoryString( $data, $slotId );
		else if ( type == 6 )
			return new ObjectTool( null, "", "", "", "" ).fromInventoryString( $data, $slotId );
		else
			Log.out( "Slots.createObjectFromInventoryString - type: " + type + "  NOT FOUND", Log.ERROR );
		
		return new ObjectInfo( null, ObjectInfo.OBJECTINFO_INVALID );
	}

	public function addDefaultData():void {
		Log.out( "Slots.addDefaultData", Log.WARN );
		initializeSlots();

		// is guid model OR instance?
		// its the MODEL guid, since models have default oxelPersistence, instances have specific oxelPersistence
		// so this message is handle by the model class.
		// might need to be a table driven event also.
		// so the default oxelPersistence is in the "class inventory" table
		_owner.loaded = true;
		InventorySlotEvent.create( InventorySlotEvent.DEFAULT_REQUEST, _owner.guid, _owner.guid, 0, null );
	}

	public function fromObject( $info:Object ):void {	
		if ( $info && $info.slot0 ) {
			var index:int;
			setItemData( index, createObjectFromInventoryString( $info.slot0, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot1, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot2, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot3, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot4, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot5, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot6, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot7, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot8, index++ ) );
			setItemData( index, createObjectFromInventoryString( $info.slot9, index++ ) );
		}
	}


	public function toObject( $info:Object ):void {
		$info.slot0	= _items[0].asInventoryString();
		$info.slot1	= _items[1].asInventoryString();
		$info.slot2	= _items[2].asInventoryString();
		$info.slot3	= _items[3].asInventoryString();
		$info.slot4	= _items[4].asInventoryString();
		$info.slot5	= _items[5].asInventoryString();
		$info.slot6	= _items[6].asInventoryString();
		$info.slot7	= _items[7].asInventoryString();
		$info.slot8	= _items[8].asInventoryString();
		$info.slot9	= _items[9].asInventoryString();
	}
	
	private function setItemData( $slot:int, $data:ObjectInfo ):void {
		// find an empty slot
		if ( -1 == $slot )
			$slot = findFirstEmptySlot();

		if ( 0 > $slot || 9 < $slot ) {
			Log.out( "Slots.setItemData - invalid slot: " + $slot, Log.ERROR );
			throw new Error( "Slots.setItemData - invalid slot: " + $slot );
		}
		if ( null == $data ) {
			Log.out( "Slots.setItemData - invalid data: " + $data, Log.ERROR );
			throw new Error( "Slots.setItemData - invalid data: " + $data );
		}
		
		_items[$slot] = $data;
	}
	
	
	private function findFirstEmptySlot():int {
		for ( var i:int; i < _items.length; i++ ) {
			//Log.out( "Slots.findFirstEmptySlot: " + i );
			if ( ObjectInfo.OBJECTINFO_EMPTY == _items[i].objectType ) {
				return i;
			}
		}
		return -1;
	}
	
	static private function pickToolSlots():void {
		CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.DELETE_OXEL ) );
	}
	
	static private function noneSlots():void {
		CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) );
	}
	

	private function initializeSlots():void {
		for ( var i:int=0; i < ITEM_COUNT; i++ ) {
			setItemData( i, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) );
		}
	}
}
}
