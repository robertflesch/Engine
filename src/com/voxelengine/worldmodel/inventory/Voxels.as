/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {

import com.voxelengine.events.InventoryEvent;

import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.models.SecureInt;

public class Voxels
{
	private var  _items:Vector.<SecureInt> = new Vector.<SecureInt>( TypeInfo.MAX_TYPE_INFO, true );
	public function get items():Vector.<SecureInt>  { return _items; }
	private var _owner:Inventory;

	public function Voxels( $owner:Inventory ) {
		_owner = $owner;
		
		var allTypes:Vector.<TypeInfo> = TypeInfo.typeInfo;
		for ( var typeId:int = 0; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
			_items[typeId] = new SecureInt( 0 );
			
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.CHANGE, 			change );
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.COUNT_REQUEST,	count );
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.TYPES_REQUEST,	types );
	}

	public function unload():void {
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.CHANGE, 		change );
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.COUNT_REQUEST,	count );
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.TYPES_REQUEST,	types );
	}
	
	// This returns an Array which holds the typeId and the count of those voxels
	public function types(e:InventoryVoxelEvent):void 
	{
		if ( e.networkId == _owner.ownerGuid ) {
			const cat:String = (e.result as String).toUpperCase();
			if ( cat == "ALL" ) {
				InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.TYPES_RESULT, _owner.ownerGuid, -1, _items ) );
				return;
			}
				
			var result:Vector.<SecureInt> = new Vector.<SecureInt>(TypeInfo.MAX_TYPE_INFO, true);
			for ( var typeId:int = 0; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ ) {
				result[typeId] = new SecureInt( 0 );
				var ti:TypeInfo = TypeInfo.typeInfo[typeId];
				if ( ti ) { 
					var catData:String = ti.category;
					if ( cat == catData.toUpperCase() ) {
						if ( 0 < _items[typeId].val )
							result[typeId].val	= _items[typeId].val;
						else
							result[typeId].val	= -2;
					}
					else
						result[typeId].val	= -1;
				}
			}

			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.TYPES_RESULT, _owner.ownerGuid, -1, result ) );
		}
	}
	
	public function count(e:InventoryVoxelEvent):void 
	{
		if ( null == _items )
			return;
		if ( e.networkId == _owner.ownerGuid ) {
			var typeId:int = e.typeId;
			var voxelCount:int = _items[typeId].val;
			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.COUNT_RESULT, _owner.ownerGuid, typeId, voxelCount ) );
		}
		//Log.out( "Voxels.voxelCount - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	public function addTestData():void {
		for ( var typeId:int = 0; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ ) {
			if ( _items[typeId] )
				_items[typeId].val = Math.random() * 1000000;
		}
        _owner.changed = true;
        InventoryEvent.create( InventoryEvent.SAVE_REQUEST, _owner.ownerGuid, null );
	}
	
	public function change(e:InventoryVoxelEvent):void {
		//InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.CHANGE, Network.userId, typeIdToUse, amountInGrain0 ) );		
		if ( e.networkId == _owner.ownerGuid ) {
			if ( null == _items ) {
				Log.out( "Voxels.change - ITEMS NULL", Log.WARN );
				return;
			}
			var typeId:int = e.typeId;
			var changeAmount:int = e.result as int;
			var voxelCount:int = _items[typeId].val;
			voxelCount += changeAmount;
			_items[typeId].val = voxelCount;
			//Log.out( "Voxels.change - Succeeded test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.COUNT_RESULT, _owner.ownerGuid, typeId, voxelCount ) );
            _owner.changed = true;
            InventoryEvent.create( InventoryEvent.SAVE_REQUEST, _owner.ownerGuid, null );
		}
		//Log.out( "Voxels.change - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	public function fromObject( $ba:ByteArray ):void {
		const typesCount:int = $ba.readInt();
		for ( var i:int = 0; i < typesCount; i++ ) {
			if ( $ba.bytesAvailable < 4 )
				return;
			_items[i].val = $ba.readInt();
		}
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray { 
		$ba.writeInt( TypeInfo.MAX_TYPE_INFO );
		for ( var i:int = 0; i < TypeInfo.MAX_TYPE_INFO; i++ ) {
			$ba.writeInt( _items[i].val )
		}
		return $ba; 
	}
}
}
