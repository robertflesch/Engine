/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.GUI.Hub;
import com.voxelengine.worldmodel.models.SecureInt;
import flash.events.EventDispatcher;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Persistance;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.ObjectInfo;

import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.InventoryPersistanceEvent;

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
		
		var allTypes:Vector.<TypeInfo> = Globals.typeInfo;
		for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
			_items[typeId] = new SecureInt( 0 );
			
		InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, 			voxelChange );
		InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST,	voxelCount );
		InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST,	voxelTypes );
		
		//addVoxelTestData();	
	}

	// This returns an Array which holds the typeId and the count of those voxels
	public function voxelTypes(e:InventoryVoxelEvent):void 
	{
		const cat:String = (e.result as String).toUpperCase();
		if ( cat == "ALL" ) {
			InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _networkId, -1, _items ) );
			return;
		}
			
		var result:Vector.<SecureInt> = new Vector.<SecureInt>(TypeInfo.MAX_TYPE_INFO,true);
		// This iterates thru the keys
		for ( var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
		{
			var catData:String = Globals.typeInfo[typeId].category;
			if ( cat == catData.toUpperCase() && 0 < _items[typeId].val )
				result[typeId].val	= _items[typeId].val;
			else;
				result[typeId].val	= -1;
		}

		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _networkId, -1, result ) );
	}
	
	
	public function voxelCount(e:InventoryVoxelEvent):void 
	{
		if ( null == _items )
			return;
		if ( e.ownerGuid == _networkId ) {
			var typeId:int = e.typeId;
			var voxelCount:int = _items[typeId].val;
			InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, _networkId, typeId, voxelCount ) );
			return;
		}
		Log.out( "Voxels.voxelCount - Failed test of e.ownerGuid: " + e.ownerGuid + " == _networkId: " + _networkId, Log.WARN );
	}
	
	
	public function addVoxelTestData():void {
		_items[Globals.STONE].val = 1234;
		_items[Globals.DIRT].val = 432;
		_items[Globals.GRASS].val = 123456789;
	}
			
	
	public function voxelChange(e:InventoryVoxelEvent):void {
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
		return $ba; 
	}
}
}
