/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.events.InventoryModelEvent;
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.models.SecureInt;

public class Voxels
{
	private var  _items:Vector.<SecureInt> = new Vector.<SecureInt>( TypeInfo.MAX_TYPE_INFO, true );
	private var _networkId:String;
	private var _changed:Boolean;
	
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void  { _changed = value; }
	
	public function get items():Vector.<SecureInt>  { return _items; }

	public function Voxels( $networkId:String ) {
		_networkId = $networkId;
		
		var allTypes:Vector.<TypeInfo> = TypeInfo.typeInfo;
		for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
			_items[typeId] = new SecureInt( 0 );
			
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, 			change );
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST,	count );
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST,	types );
	}

	public function unload():void {
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, 		change );
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST,	count );
		InventoryVoxelEvent.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST,	types );
	}
	
	// This returns an Array which holds the typeId and the count of those voxels
	public function types(e:InventoryVoxelEvent):void 
	{
		if ( e.networkId == _networkId ) {
			const cat:String = (e.result as String).toUpperCase();
			if ( cat == "ALL" ) {
				InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _networkId, -1, _items ) );
				return;
			}
				
			var result:Vector.<SecureInt> = new Vector.<SecureInt>(TypeInfo.MAX_TYPE_INFO, true);
			for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ ) {
				result[typeId] = new SecureInt( 0 );
				var ti:TypeInfo = TypeInfo.typeInfo[typeId]
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

			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _networkId, -1, result ) );
		}
	}
	
	public function count(e:InventoryVoxelEvent):void 
	{
		if ( null == _items )
			return;
		if ( e.networkId == _networkId ) {
			var typeId:int = e.typeId;
			var voxelCount:int = _items[typeId].val;
			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, _networkId, typeId, voxelCount ) );
			return;
		}
		//Log.out( "Voxels.voxelCount - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	public function addTestData():void {
		for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ ) {
			if ( _items[typeId] )
				_items[typeId].val = Math.random() * 1000000;
		}
		changed = true;
	}
	
	public function change(e:InventoryVoxelEvent):void {
		//InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, Network.userId, typeIdToUse, amountInGrain0 ) );		
		if ( e.networkId == _networkId ) {
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
			InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, _networkId, typeId, voxelCount ) );
			changed = true;
			return;
		}
		//Log.out( "Voxels.change - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {}
	public function toPersistance( $dbo:DatabaseObject ):void {}

	public function fromByteArray( $ba:ByteArray ):void {
		const typesCount:int = $ba.readInt();
		for ( var i:int; i < typesCount; i++ ) {
			if ( $ba.bytesAvailable < 4 )
				return;
			_items[i].val = $ba.readInt();
		}
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray { 
		$ba.writeInt( TypeInfo.MAX_TYPE_INFO )
		for ( var i:int; i < TypeInfo.MAX_TYPE_INFO; i++ ) {
			$ba.writeInt( _items[i].val )
		}
		changed = false;
		return $ba; 
	}
}
}
