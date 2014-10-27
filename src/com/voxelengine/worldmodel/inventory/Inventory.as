/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
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
		
		private var _items:Vector.<InventoryObjects>;
		
		public function Inventory( $guid:String ) 
		{
			_guid = $guid;
			registerClassAlias("InventoryObjects", InventoryObjects);
		}
		
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
			if ( 0 < $ba.bytesAvailable )
				_items = $ba.readObject() as Vector.<InventoryObjects>;
			return;
		}
		
		private function asByteArray():ByteArray {

			var ba:ByteArray = new ByteArray();
			for each ( var item:InventoryObjects in _items )
				ba.writeObject( item );
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
				Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, inventoryLoad );
				Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, inventoryLoadFailed );
				Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_REQUEST, _guid ) );
			}
		}
		
		private function inventoryLoad( $inve:InventoryPersistanceEvent ):void
		{
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, inventoryLoad );
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, inventoryLoadFailed );
			fromPersistance( $inve.dbo );
		}
		
		private function inventoryLoadFailed( $inve:InventoryPersistanceEvent ):void
		{
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, inventoryLoad );
			Persistance.eventDispatcher.removeEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, inventoryLoadFailed );
			Log.out( "Inventory.inventoryLoadFailed - No object for this avatar, this is ok for first time use.", Log.DEBUG );
			_items = new Vector.<InventoryObjects>();
			save();
		}
		
		public function save():void {
			if ( Globals.online ) {
				if ( _dbo )
					toPersistance();
				else
					var ba:ByteArray = asByteArray();
				addSaveEvents();
				Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_SAVE_REQUEST, _guid, _dbo, ba ) );
			}
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
			fromPersistance( $inve.dbo );
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