/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.*;

public class Slots
{
	static public const ITEM_COUNT:int = 10;
	
	private var _items:Vector.<ObjectInfo> = new Vector.<ObjectInfo>(10, true);
	private var _owner:String;
	private var _changed:Boolean;
	
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void  { _changed = value; }
	
	public function get items():Vector.<ObjectInfo>  { return _items; }

	public function Slots( $owner:String ) {
		// Do I need to unregister this?
		InventorySlotEvent.addListener( InventorySlotEvent.INVENTORY_SLOT_CHANGE,	slotChange );
		//InventorySlotEvent.addListener( InventorySlotEvent.INVENTORY_DEFAULT_RESPONSE, defaultResponse );
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
		InventorySlotEvent.removeListener( InventorySlotEvent.INVENTORY_SLOT_CHANGE,	slotChange );
	}
	
	public function slotChange(e:InventorySlotEvent):void {
		Log.out( "SlotsManager.slotChange slot: " + e.slotId + "  item: " + e.data );
		if ( _owner == e.ownerGuid ) {
			if ( _items ) {
				if ( null == e.data )
					setItemData( e.slotId, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) );
				else
					setItemData( e.slotId, e.data );
				changed = true;
			}
			else
				Log.out( "SlotsManager.slotChange _slots container not initialized", Log.WARN );
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
	
	public function fromPersistance( $dbo:DatabaseObject ):void {	
		if ( $dbo && $dbo.slot0 ) {
			var index:int;
			setItemData( index, createObjectFromInventoryString( $dbo.slot0, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot1, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot2, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot3, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot4, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot5, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot6, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot7, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot8, index++ ) );
			setItemData( index, createObjectFromInventoryString( $dbo.slot9, index++ ) );
		}
		else {
			addSlotDefaultData();		
		}
	}
	
	public function toPersistance( $dbo:DatabaseObject ):void {
		$dbo.slot0	= _items[0].asInventoryString();
		$dbo.slot1	= _items[1].asInventoryString();
		$dbo.slot2	= _items[2].asInventoryString();
		$dbo.slot3	= _items[3].asInventoryString();
		$dbo.slot4	= _items[4].asInventoryString();
		$dbo.slot5	= _items[5].asInventoryString();
		$dbo.slot6	= _items[6].asInventoryString();
		$dbo.slot7	= _items[7].asInventoryString();
		$dbo.slot8	= _items[8].asInventoryString();
		$dbo.slot9	= _items[9].asInventoryString();
		changed = false;
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
	
	import flash.utils.getQualifiedClassName;
	public function addSlotDefaultData():void {
		Log.out( "Slots.addSlotDefaultData", Log.WARN );
		initializeSlots();
		InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_DEFAULT_REQUEST, _owner, _owner, 0, null ) );
	}
	
	
	static private function pickToolSlots():void {
//		EditCursor.cursorOperation = EditCursor.CURSOR_OP_DELETE;
//		EditCursor.setPickColorFromType( EditCursor.cursorType )
//		EditCursor.editing = true;
		CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.DELETE_OXEL ) );
	}
	
	static private function noneSlots():void {
//		EditCursor.cursorOperation = EditCursor.CURSOR_OP_NONE;
//		EditCursor.editing = false;
		CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) );
	}
	

	private function initializeSlots():void {
		for ( var i:int; i < ITEM_COUNT; i++ ) {
			setItemData( i, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) );
		}
	}

	public function fromByteArray( $ba:ByteArray ):void {}
	public function toByteArray( $ba:ByteArray ):ByteArray { return $ba; }
}
}
