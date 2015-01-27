/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import flash.events.EventDispatcher;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Network;
import com.voxelengine.server.Persistance;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.ObjectInfo;

import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.InventoryPersistanceEvent;

public class Inventory
{
	private var  _slots:Vector.<ObjectInfo> = new Vector.<ObjectInfo>(10, true);
	private var _models:Array = new Array();
	private var _voxels:Array;
	private var _guid:String;

	// support data for persistance
	private var _dbo:DatabaseObject  = null;							
	private var _createdDate:Date;
	private var _modifiedDate:Date;
	private var _changed:Boolean;
	private function get changed():Boolean { return _changed; }
	private function set changed(value:Boolean):void  { _changed = value; }

	public function Inventory( $ownerGuid:String ) {

		_guid = $ownerGuid;
		_voxels = new Array();
		var allTypes:Array = Globals.typeInfo;
		for (var key:String in allTypes )
			_voxels[key] = 0;
			
		addVoxelTestData();
	}
	
	public function slotChange(e:InventorySlotEvent):void 
	{
		var slotId:int = e.slotId;
		var item:ObjectInfo = e.item;
		Log.out( "InventoryManager.slotChange slot: " + slotId + "  item: " + item );
		_slots[slotId] = item;
		// save it here...
	}
	
	// This returns an Array which holds the typeId and the count of those voxels
	public function voxelTypes(e:InventoryVoxelEvent):void 
	{
		const cat:String = (e.result as String).toUpperCase();
		if ( cat == "ALL" ) {
			InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _guid, -1, _voxels ) );
			return;
		}
			
		var result:Array = [];
		// This iterates thru the keys
		for (var key:String in _voxels) {
			var catData:String = Globals.typeInfo[key].category;
			if ( cat == catData.toUpperCase() && 0 < _voxels[key] )
				result[key]	= _voxels[key];
		}

		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, _guid, -1, result ) );
	}
	
	public function voxelCount(e:InventoryVoxelEvent):void 
	{
		if ( e.ownerGuid == _guid && null != _voxels ) {
			var typeId:int = e.typeId;
			var voxelCount:int = _voxels[typeId];
			InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, _guid, typeId, voxelCount ) );
		}
	}
	
	public function modelCount(e:InventoryModelEvent):void 
	{
		//var modelId:String = e.guid;
		//var modelCount:int = _models[modelId];
		//InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, _guid, modelId, modelCount ) );
	}
	
	public function addModelTestData():void {
		_models["Pick"] = 1;
		_models["Shovel"] = 1;
	}
	
	public function addVoxelTestData():void {
		_voxels[Globals.STONE] = 1234;
		_voxels[Globals.DIRT] = 432;
		_voxels[Globals.GRASS] = 123456789;
	}
	
	public function modelIncrement(e:InventoryModelEvent):void 
	{
		
	}
	
	public function modelDecrement(e:InventoryModelEvent):void 
	{
		
	}
	
	public function voxelChange(e:InventoryVoxelEvent):void 
	{
		var typeId:int = e.typeId;
		var changeCount:int = int( e.result );
		var count:int = _voxels[typeId];
		Log.out( "Inventory.voxelChange - trying to change type id: " + Globals.typeInfo[typeId].name + " of count: " + changeCount + " current count: " + _voxels[typeId] );
		
		count += changeCount;
		_voxels[typeId] = count;
		Log.out( "Inventory.voxelChange - changed: " + _voxels[typeId] );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, _guid, typeId, count ) );			
//		Log.out( "Inventory.voxelChange - FAILED to remove a type has less then request count - id: " + e.type + " of count: " + resultCount + " current count: " + count, Log.ERROR );
	}
	
	public function get models():Array
	{
		return _models;
	}
	
	
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_REQUEST, _guid ) );
		}
	}
	
	public function save():void {
		if ( Globals.online && changed ) {
			Log.out( "Inventory.save - Saving User Inventory", Log.WARN );
			if ( _dbo )
				toPersistance();
			else
				var ba:ByteArray = asByteArray();
			addSaveEvents();
			Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_SAVE_REQUEST, _guid, _dbo, ba ) );
		}
		else
			Log.out( "Inventory.save - NOT Saving User Inventory, either offline or NOT changed", Log.DEBUG );

	}
	
	public function add( $type:int, $item:* ):void {	
	}
	
	//////////////////////////////////////////////////////////////////
	// Persistance
	//////////////////////////////////////////////////////////////////
	private function fromPersistance( $dbo:DatabaseObject ):void {
		
		_createdDate	= $dbo.createdDate;
		_modifiedDate   = $dbo.modifiedDate;
		_dbo 			= $dbo;
		
		if ( $dbo.data ) {
			var ba:ByteArray= $dbo.data 
			ba.uncompress();
			fromByteArray( ba );
		}
	}
	
	private function toPersistance():void {
		_dbo.data 			= asByteArray();
	}
	
	private function fromByteArray( $ba:ByteArray ):void {
		if ( 0 == $ba.bytesAvailable )
			return;
		//_items = new Vector.<InventoryObject>();	
		//var itemCount:int = $ba.readInt();
		//for ( var i:int; i < itemCount; i++ ) {
			//var io:InventoryObject = new InventoryObject();
			//io.fromByteArray( $ba )
			//items.push( io );
		//}
	}
	
	private function asByteArray():ByteArray {

		var ba:ByteArray = new ByteArray();
		//ba.writeInt( items.length );
		//for each ( var item:InventoryObject in items )
			//item.toByteArray( ba );
		//ba.compress();	
		return ba;	
	}
	
	private function addLoadEvents():void {
			Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, InventoryLoadSuccess );
			Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, InventoryLoadFailed );
	}
	
	private function removeLoadEvents():void {
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, InventoryLoadSuccess );
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, InventoryLoadFailed );
		
	}
	
	private function InventoryLoadSuccess( $inve:InventoryPersistanceEvent ):void
	{
		removeLoadEvents();
		fromPersistance( $inve.dbo );
	}
	
	private var _generateNewInventory:Boolean;
	private function InventoryLoadFailed( $inve:InventoryPersistanceEvent ):void
	{
		removeLoadEvents();
		Log.out( "Inventory.InventoryLoadFailed - No object for this avatar, this is ok for first time use.", Log.DEBUG );
		//if ( false == _generateNewInventory ) {
			//generateNewInventory();
			//save();
		//}
	}
	
	private function addSaveEvents():void {
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_SAVE_SUCCEED, saveSucceed );
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_SAVE_FAILED, saveFailed );
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_CREATE_SUCCEED, saveSucceed );
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_CREATE_FAILED, createFailed );
	}
	
	private function removeSaveEvents():void {
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_SAVE_SUCCEED, saveSucceed );
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_SAVE_FAILED, saveFailed );
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_CREATE_SUCCEED, saveSucceed );
		Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_CREATE_FAILED, createFailed );
	}
	
	private function saveSucceed( $inve:InventoryPersistanceEvent ):void
	{
		removeSaveEvents();
		Log.out( "Inventory.saveSucceed" );
	}
	
	private function saveFailed( $inve:InventoryPersistanceEvent ):void
	{
		removeSaveEvents();
		Log.out( "Inventory.saveFailed - MAY BE (error #2032)  The method SaveObjectChanges can only be called when connected to a game", Log.ERROR );
	}
	
	private function createFailed( $inve:InventoryPersistanceEvent ):void
	{
		removeSaveEvents();
		Log.out( "Inventory.createFailed - Failed to create new Inventory object for this avatar.", Log.ERROR );
	}
}
}


/*
	private function generateNewInventory():void {
		_generateNewInventory = true;
		_items = new Vector.<InventoryObject>();
		var item1:InventoryModel = new InventoryModel();
		item1.guid = "Pick";
		item1.type = 1;
		_items.push( item1 );
		var item2:InventoryModel = new InventoryModel();
		item2.guid = "Shovel";
		item2.type = 2;
		_items.push( item2 );
		changed = true;
	}

	public function add( $type:int, $guid:String ):void {
		var item:InventoryModel = new InventoryModel();
		item.type = $type;
		item.guid = $guid;
		items.push( item );
		changed = true;
	}
	
	public function toString():String {
		// FIXME
		throw new Error( "Inventory.toString not implemented" );
		return null;
	}
}*/