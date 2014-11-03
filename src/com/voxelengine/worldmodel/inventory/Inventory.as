/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.InventoryEvent;
	import com.voxelengine.events.InventoryPersistanceEvent;
	import com.voxelengine.server.Persistance;

	/**
	 * ...
	 * @author Bob
	 */
	public class Inventory 
	{
		private var _dbo:DatabaseObject  = null;							
		private var _createdDate:Date;
		private var _modifiedDate:Date;
		private var _guid:String;
		
		private var _items:Vector.<InventoryObject>;
		
		public function get items():Vector.<InventoryObject> {
			if ( null == _items ) 
				_items = new Vector.<InventoryObject>();	
				
			return _items;
		}

		
		public function Inventory( $guid:String ) 
		{
			_guid = $guid;
		}
		
		private function generateNewInventory():void {
			_generateNewInventory = true;
			_items = new Vector.<InventoryObject>();
			var item1:InventoryObject = new InventoryObject();
			item1.guid = "Pick";
			item1.type = 1;
			_items.push( item1 );
			var item2:InventoryObject = new InventoryObject();
			item2.guid = "Shovel";
			item2.type = 2;
			_items.push( item2 );
		}

		public function add( $type:int, $guid:String ):void {
			var item:InventoryObject = new InventoryObject();
			item.type = $type;
			item.guid = $guid;
			items.push( item );
		}

		//////////////////////////////////////////////////////////////////
		// Persistance
		//////////////////////////////////////////////////////////////////
		public function fromPersistance( $dbo:DatabaseObject ):void {
			
			_createdDate	= $dbo.createdDate;
			_modifiedDate   = $dbo.modifiedDate;
			_dbo 			= $dbo;
			
			if ( $dbo.data ) {
				var ba:ByteArray= $dbo.data 
				ba.uncompress();
				fromByteArray( ba );
			}
		}
		
		public function toPersistance():void {
			_dbo.data 			= asByteArray();
		}
		
		private function fromByteArray( $ba:ByteArray ):void {
			if ( 0 == $ba.bytesAvailable )
				return;
			_items = new Vector.<InventoryObject>();	
			var itemCount:int = $ba.readInt();
			for ( var i:int; i < itemCount; i++ ) {
				var io:InventoryObject = new InventoryObject();
				io.fromByteArray( $ba )
				items.push( io );
			}
		}
		
		private function asByteArray():ByteArray {

			var ba:ByteArray = new ByteArray();
			ba.writeInt( _items.length );
			for each ( var item:InventoryObject in _items )
				item.toByteArray( ba );
			ba.compress();	
			return ba;	
		}
		
		public function toString():String {
			// FIXME
			throw new Error( "Inventory.toString not implemented" );
			return null;
		}
		
		
		public function load():void {
			if ( Globals.online ) {
				addLoadEvents();
				Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_REQUEST, _guid ) );
			}
		}
		
		private function addLoadEvents():void {
				Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, inventoryLoadSuccess );
				Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, inventoryLoadFailed );
		}
		
		private function removeLoadEvents():void {
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, inventoryLoadSuccess );
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, inventoryLoadFailed );
			
		}
		
		private function inventoryLoadSuccess( $inve:InventoryPersistanceEvent ):void
		{
			removeLoadEvents();
			fromPersistance( $inve.dbo );
		}
		
		private var _generateNewInventory:Boolean;
		private function inventoryLoadFailed( $inve:InventoryPersistanceEvent ):void
		{
			removeLoadEvents();
			Log.out( "Inventory.inventoryLoadFailed - No object for this avatar, this is ok for first time use.", Log.DEBUG );
			if ( false == _generateNewInventory ) {
				generateNewInventory();
				save();
			}
		}
		
		public function save():void {
			if ( Globals.online ) {
				Log.out( "Inventory.save - Saving User Inventory", Log.WARN );
				if ( _dbo )
					toPersistance();
				else
					var ba:ByteArray = asByteArray();
				addSaveEvents();
				Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_SAVE_REQUEST, _guid, _dbo, ba ) );
			}
			else
				Log.out( "Inventory.save - NOT NOT NOT Saving User Inventory", Log.WARN );

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
		}
		
		private function saveFailed( $inve:InventoryPersistanceEvent ):void
		{
			removeSaveEvents();
			Log.out( "Inventory.saveFailed - Why did this happen?", Log.ERROR );
		}
		
		private function createFailed( $inve:InventoryPersistanceEvent ):void
		{
			removeSaveEvents();
			Log.out( "Inventory.createFailed - Failed to create new inventory object for this avatar.", Log.ERROR );
		}
	}
}