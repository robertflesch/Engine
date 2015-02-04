/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.worldmodel.models.SecureInt;
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
		
		Log.out( "Models.constructor - registering change event for: " + $networkId , Log.WARN );
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_CHANGE,	modelChange );
	}

	public function modelChange(e:InventoryModelEvent):void {
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
	
			return;
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {}
	public function toPersistance( $dbo:DatabaseObject ):void {}

	public function fromByteArray( $ba:ByteArray ):void {
		//const typesCount:int = $ba.readInt();
		//var itemGuid:String;
		//var itemCount:int;
		//for ( var i:int; i < typesCount; i++ ) {
			//itemGuid = $ba.readUTF();
			//itemCount = $ba.readInt();
			//_items[itemGuid] = new SecureInt( itemCount );
		//}
		addModelTestData();	
	}
	
	private function addModelTestData():void {
		_items["DC6055B8-13A7-C598-2D46-6B78A23669D2"] = new SecureInt( 99 );
		_items["INVALID"] = new SecureInt( 666 );
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray { 
		$ba.writeInt( _items.length )
		for ( var k:String in _items ) {	
			$ba.writeUTF( k ) // guid
			$ba.writeInt( _items[k].val ) // amount of items
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
