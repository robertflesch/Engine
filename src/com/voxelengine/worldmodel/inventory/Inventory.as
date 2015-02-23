/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.events.InventoryEvent;
import flash.events.EventDispatcher;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import playerio.DatabaseObject;

import org.flashapi.swing.Alert;
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.persistance.Persistance;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.ObjectInfo;

import com.voxelengine.events.*;

public class Inventory
{
	private var  _slots:Slots
	private var _voxels:Voxels;
	private var _models:Models;
	private var _networkId:String;

	// support data for persistance
	private var _dbo:DatabaseObject  = null;							
	private var _createdDate:Date;
	private var _modifiedDate:Date;
	private var _generateNewInventory:Boolean;

	public function get slots():Slots  { return _slots; }
	public function get voxels():Voxels  { return _voxels; }
	public function get models():Models  { return _models; }
	public function get networkId():String { return _networkId; }
	
	public function Inventory( $networkId:String ) {
		_slots = new Slots( $networkId );
		_networkId = $networkId;
		_voxels = new Voxels( $networkId );
		_models = new Models( $networkId );
	}
	
	public function unload():void {
		Log.out( "Inventory.unload - networkId: " + _networkId, Log.WARN );
		_slots.unload();
		_voxels.unload();
		_models.unload();
	}
		
	private function changed():Boolean {
		if ( _slots.changed || _voxels.changed || _models.changed )
			return true;
		return false;
	}
	
	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	public function save():void {
		if ( Globals.online && changed() ) {
			Log.out( "Inventory.save - Saving User Inventory networkId: " + networkId, Log.WARN );
			if ( _dbo )
				toPersistance();
			else {
				var ba:ByteArray = new ByteArray();	
				ba = asByteArray( ba );
			}
			addSaveEvents();
			InventoryPersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, inventoryCreateSuccess );
			InventoryPersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, inventorySaveSuccess );
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.SAVE_REQUEST, _networkId, _dbo, ba ) );
		}
		else
			Log.out( "Inventory.save - NOT Saving User Inventory, either offline or NOT changed - networkId: " + networkId, Log.DEBUG );
	}
	
	private function toPersistance():void {
		_slots.toPersistance(_dbo);
		_voxels.toPersistance(_dbo);
		_models.toPersistance(_dbo);
		var ba:ByteArray = new ByteArray(); 
		_dbo.data 			= asByteArray( ba );
	}

	public function asByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeUTF( _networkId );
		_slots.asByteArray( $ba );
		_voxels.asByteArray( $ba );
		_models.asByteArray( $ba );
		$ba.compress();
		return $ba;	
	}
	
	private function inventorySaveSuccess(e:InventoryPersistanceEvent):void 
	{
		InventoryPersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, inventoryCreateSuccess );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, inventorySaveSuccess );
	}
	
	private function inventoryCreateSuccess(e:InventoryPersistanceEvent):void 
	{
		Log.out( "Inventory.inventoryCreateSuccess - setting dbo for - networkId: " + networkId, Log.DEBUG );
		_dbo = e.dbo;
		InventoryPersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, inventoryCreateSuccess );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, inventorySaveSuccess );
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_REQUEST, _networkId ) );
		}
	}

	// If $dbo is null then the default data is loaded
	private function fromPersistance( $dbo:DatabaseObject ):void {
		
		if ( $dbo ) {
			_createdDate	= $dbo.createdDate;
			_modifiedDate   = $dbo.modifiedDate;
			_dbo 			= $dbo;
		}
		
		// Slot data is stored as fields for easy analysis
		// we can know what user carry around
		_slots.fromPersistance( $dbo );
		_voxels.fromPersistance( $dbo );
		_models.fromPersistance( $dbo);
		
		if ( $dbo && $dbo.data ) {
			var ba:ByteArray = $dbo.data 
			if ( ba && 0 < ba.bytesAvailable ) {
				ba.uncompress();
				fromByteArray( ba );
			}
		}
		else {
			_voxels.addTestData();
//			_models.addTestData();
		}
	}
	
	private function fromByteArray( $ba:ByteArray ):void {
		var ownerId:String = $ba.readUTF();
		_slots.fromByteArray( $ba );
		_voxels.fromByteArray( $ba );
		_models.fromByteArray( $ba );
	}
	
	private function addLoadEvents():void {
		InventoryPersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, inventoryLoadSuccess );
		InventoryPersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, inventoryLoadFailed );
		InventoryPersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, inventoryNotFound );
	}
	
	private function removeLoadEvents():void {
		InventoryPersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, inventoryLoadSuccess );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.LOAD_FAILED, inventoryLoadFailed );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.LOAD_NOT_FOUND, inventoryNotFound );
	}
	
	private function inventoryNotFound(e:InventoryPersistanceEvent):void 
	{
		// this occurs on first time logging in.
		removeLoadEvents();
		fromPersistance( null );
		InventoryManager.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_RESPONSE, _networkId, this ) );
	}
	
	private function inventoryLoadSuccess( $inve:InventoryPersistanceEvent ):void
	{
		removeLoadEvents();
		fromPersistance( $inve.dbo );
		InventoryManager.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_RESPONSE, _networkId, this ) );
	}
	
	private function inventoryLoadFailed( $inve:InventoryPersistanceEvent ):void
	{
		removeLoadEvents();
		(new Alert( "ERROR LOADING USER INVENTORY - Please post on forums" )).display();
	}
	
	private function addSaveEvents():void {
		InventoryPersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		InventoryPersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		InventoryPersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		InventoryPersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, createFailed );
	}
	
	private function removeSaveEvents():void {
		InventoryPersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		InventoryPersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, createFailed );
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
