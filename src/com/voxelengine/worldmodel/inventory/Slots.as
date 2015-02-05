/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.InventoryPersistanceEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.ObjectInfo;

public class Slots
{
	static public const ITEM_COUNT:int = 10;
	
	private var _items:Vector.<ObjectInfo> = new Vector.<ObjectInfo>(10, true);
	private var _networkId:String;
	private var _changed:Boolean;
	
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void  { _changed = value; }
	
	public function get items():Vector.<ObjectInfo>  { return _items; }

	public function Slots( $networkId:String ) {
		// Do I need to unregister this?
		InventoryManager.addListener( InventorySlotEvent.INVENTORY_SLOT_CHANGE,	slotChange );
		_networkId = $networkId;
	}
	
	public function slotChange(e:InventorySlotEvent):void {
		Log.out( "SlotsManager.slotChange slot: " + e.slotId + "  item: " + e.item );
		if ( _items ) {
			if ( null == e.item )
				_items[e.slotId].reset( "" );
			else
				_items[e.slotId] = e.item;
			changed = true;
		}
		else
			Log.out( "SlotsManager.slotChange _slots container not initialized", Log.WARN );
	}
	
	private function createObjectFromInventoryString( $data:String ):ObjectInfo {
		// find the first comma so we can get the substring with the object type
		var type:int = int( $data.charAt(0) );
		if ( type == 1 )
			return new ObjectInfo( ObjectInfo.OBJECTINFO_EMPTY, "" );		
		else if ( type == 2 )
			return new TypeInfo( 0 ).fromInventoryString( $data ); 
		else if ( type == 3 )
			return new ObjectInfo( ObjectInfo.OBJECTINFO_MODEL, "" ).fromInventoryString( $data );
		else if ( type == 4 )
			return new ObjectInfo( ObjectInfo.OBJECTINFO_ACTION, "" ).fromInventoryString( $data );
		else if ( type == 5 )
			return new ObjectInfo( ObjectInfo.OBJECTINFO_ACTION, "" ).fromInventoryString( $data );
		
		return new ObjectInfo( ObjectInfo.OBJECTINFO_INVALID, "" );
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {	
		if ( $dbo && $dbo.slot0 ) {
			_items[0] = createObjectFromInventoryString( $dbo.slot0 );
			_items[1] = createObjectFromInventoryString( $dbo.slot1 );
			_items[2] = createObjectFromInventoryString( $dbo.slot2 );
			_items[3] = createObjectFromInventoryString( $dbo.slot3 );
			_items[4] = createObjectFromInventoryString( $dbo.slot4 );
			_items[5] = createObjectFromInventoryString( $dbo.slot5 );
			_items[6] = createObjectFromInventoryString( $dbo.slot6 );
			_items[7] = createObjectFromInventoryString( $dbo.slot7 );
			_items[8] = createObjectFromInventoryString( $dbo.slot8 );
			_items[9] = createObjectFromInventoryString( $dbo.slot9 );
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
	
	public function addSlotDefaultData():void {

		initializeSlots();
		Log.out( "Slots.addSlotDefaultData - Loading default data into slots" , Log.WARN );
		
		var pickItem:ObjectInfo = new ObjectInfo( ObjectInfo.OBJECTINFO_MODEL, "pickItem" );
		pickItem.image = "pick.png";
		pickItem.name = "pick";
		_items[0] = pickItem;
		
		var noneItem:ObjectInfo = new ObjectInfo( ObjectInfo.OBJECTINFO_ACTION, "" );
		noneItem.image = "none.png";
		noneItem.name = "none";
		_items[1] = noneItem;
		
		changed = true;
	}

	private function initializeSlots():void {
		for ( var i:int; i < ITEM_COUNT; i++ ) {
			_items[i] = new ObjectInfo( ObjectInfo.OBJECTINFO_EMPTY, "" );
		}
	}

	public function fromByteArray( $ba:ByteArray ):void {}
	public function asByteArray( $ba:ByteArray ):ByteArray { return $ba; }
}
}
