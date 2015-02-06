/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.worldmodel.models.SecureInt;
import com.voxelengine.worldmodel.ObjectInfo;
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.InventoryModelEvent;

public class Models
{
	private var  _items:Array = [];
	private var _networkId:String;
	private var _changed:Boolean;
	
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void  { _changed = value; }
	
	public function Models( $networkId:String ) {
		_networkId = $networkId;
		
		//Log.out( "Models.constructor - registering change event for: " + $networkId , Log.WARN );
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_CHANGE,			change );
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_COUNT_REQUEST,	count );
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_LIST_REQUEST,		types );
	}
	
	// This returns an Array which holds the typeId and the count of those voxels
	public function types(e:InventoryModelEvent):void 
	{
		if ( e.networkId == _networkId ) {
			const cat:String = (e.result as String).toUpperCase();
			if ( cat == "ALL" ) {
				InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_LIST_RESULT, _networkId, "", _items ) );
				return;
			}
				
			//var result:Vector.<SecureInt> = new Vector.<SecureInt>(TypeInfo.MAX_TYPE_INFO, true);
			//for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ ) {
				//result[typeId] = new SecureInt( 0 );
				//var ti:TypeInfo = TypeInfo.typeInfo[typeId]
				//if ( ti ) { 
					//var catData:String = ti.category;
					//if ( cat == catData.toUpperCase() ) {
						//if ( 0 < _items[typeId].val )
							//rensult[typeId].val	= _items[typeId].val;
						//else
							//result[typeId].val	= -2;
					//}
					//else
						//result[typeId].val	= -1;
				//}
			//}
//
			//InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _networkId, -1, result ) );
		}
	}
	
	public function count(e:InventoryModelEvent):void 
	{
		if ( null == _items )
			return;
		if ( e.networkId == _networkId ) {
			var itemGuid:String = e.itemGuid
			var si:SecureInt = _items[itemGuid]
			var modelCount:int;
			if ( si )
				modelCount = si.val;
			InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, _networkId, e.itemGuid, modelCount ) );
			return;
		}
		//Log.out( "Models.count - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	

	public function change(e:InventoryModelEvent):void {
		Log.out( "Models.modelsChange This object owned by: " + _networkId + " event container " + e.toString(), Log.WARN );
		
		if ( e.networkId == _networkId ) {
			var itemGuid:String = e.itemGuid;
			var changeAmount:int = e.result as int;
			var modelCount:int
			if ( _items[itemGuid] ) {
				modelCount = _items[itemGuid].val;
				modelCount += changeAmount;
			}
			else {
				_items[itemGuid] = new SecureInt();
				modelCount = 1
			}
			InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, _networkId, itemGuid, modelCount ) );
			changed = true;
		}
		else
			Log.out( "Models.modelsChange - Failed test of e.networkId: " + e.networkId + " == _networkId: " + _networkId, Log.WARN );
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {}
	public function toPersistance( $dbo:DatabaseObject ):void {}

	public function fromByteArray( $ba:ByteArray ):void {
		const typesCount:int = $ba.readInt();
		var itemGuid:String;
		var itemCount:int;
		for ( var i:int; i < typesCount; i++ ) {
			itemGuid = $ba.readUTF();
			itemCount = $ba.readInt();
			_items[itemGuid] = new SecureInt( itemCount );
		}
	}
	
	public function addTestData():void {
		_items["DC6055B8-13A7-C598-2D46-6B78A23669D2"] = new SecureInt( 99 );
		_items["INVALID"] = new SecureInt( 666 );
		changed = true;
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray { 
		var count:int;
		for ( var k:String in _items ) {	
			count++;
		}
		$ba.writeInt( count ) // _items.length is invalid
		for ( var key:String in _items ) {	
			$ba.writeUTF( key ) // guid
			$ba.writeInt( _items[key].val ) // amount of items
		}
		changed = false;
		return $ba; 
	}
	
	public function modelCount(e:InventoryModelEvent):void 
	{
		//var modelId:String = e.guid;
		//var modelCount:int = _models[modelId];
		//InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, _networkId, modelId, modelCount ) );
	}
	
	public function modelIncrement(e:InventoryModelEvent):void 
	{
		
	}
	
	public function modelDecrement(e:InventoryModelEvent):void 
	{
		
	}
}
}
