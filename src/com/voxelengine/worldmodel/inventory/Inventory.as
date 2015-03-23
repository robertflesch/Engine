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

import org.flashapi.swing.Alert;
	
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.*;
import com.voxelengine.worldmodel.inventory.ObjectInfo;


public class Inventory
{
	
	private var  _slots:Slots
	private var _voxels:Voxels;
	private var _networkId:String;

	// support data for persistance
	private var _dbo:DatabaseObject  = null;							
	private var _createdDate:Date;
	private var _modifiedDate:Date;
	private var _generateNewInventory:Boolean;

	public function get slots():Slots  { return _slots; }
	public function get voxels():Voxels  { return _voxels; }
	public function get networkId():String { return _networkId; }
	
	public function Inventory( $networkId:String ) {
		_slots = new Slots( $networkId );
		_networkId = $networkId;
		_voxels = new Voxels( $networkId );
	}
	
	public function unload():void {
		Log.out( "Inventory.unload - networkId: " + _networkId, Log.WARN );
		_slots.unload();
		_voxels.unload();
	}
		
	private function changed():Boolean {
		if ( _slots.changed || _voxels.changed )
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
			PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, createSuccess );
			PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, saveSuccess );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_INVENTORY_TABLE, _networkId, _dbo, ba ) );
		}
		else
			Log.out( "Inventory.save - NOT Saving - status online: " + Globals.online + "  changed: " + changed() + "  networkId: " + networkId, Log.DEBUG );
	}
	
	private function toPersistance():void {
		_voxels.toPersistance(_dbo);
		_slots.toPersistance(_dbo);
		var ba:ByteArray = new ByteArray(); 
		_dbo.data 			= asByteArray( ba );
	}

	public function asByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeUTF( _networkId );
		_voxels.asByteArray( $ba );
		_slots.asByteArray( $ba );
		$ba.compress();
		return $ba;	
	}
	
	private function saveSuccess($pe:PersistanceEvent):void 
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, createSuccess );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, saveSuccess );
	}
	
	private function createSuccess( $pe:PersistanceEvent):void 
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		Log.out( "Inventory.createSuccess - setting dbo for - networkId: " + networkId, Log.DEBUG );
		_dbo = $pe.dbo;
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, createSuccess );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, saveSuccess );
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.DB_INVENTORY_TABLE, _networkId ) );
		}
	}

	// If $dbo is null then the default data is loaded
	private function fromPersistance( $dbo:DatabaseObject ):void {
		
		if ( $dbo ) {
			_createdDate	= $dbo.createdDate;
			_modifiedDate   = $dbo.modifiedDate;
			_dbo 			= $dbo;
		}
		
		// This tells me how many of each kind I have
		// Since the slots use voxel data, get it first
		_voxels.fromPersistance( $dbo );
		// Slot data is stored as fields for easy analysis
		// we can know what user carry around
		_slots.fromPersistance( $dbo );
		
		if ( $dbo && $dbo.data ) {
			var ba:ByteArray = $dbo.data 
			if ( ba && 0 < ba.bytesAvailable ) {
				ba.uncompress();
				fromByteArray( ba );
			}
		}
		else {
			_voxels.addTestData();
		}
	}
	
	private function fromByteArray( $ba:ByteArray ):void {
		var ownerId:String = $ba.readUTF();
		_voxels.fromByteArray( $ba );
		_slots.fromByteArray( $ba );
	}
	
	private function addLoadEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSuccess );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, notFound );
	}
	
	private function removeLoadEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, loadSuccess );
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.removeListener( PersistanceEvent.LOAD_NOT_FOUND, notFound );
	}
	
	private function notFound($pe:PersistanceEvent):void 
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		// this occurs on first time logging in.
		removeLoadEvents();
		fromPersistance( null );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_RESPONSE, _networkId, this ) );
	}
	
	private function loadSuccess( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		removeLoadEvents();
		fromPersistance( $pe.dbo );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_RESPONSE, _networkId, this ) );
	}
	
	private function loadFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		removeLoadEvents();
		(new Alert( "ERROR LOADING USER INVENTORY - Please post on forums" )).display();
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, createFailed );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, createFailed );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Inventory.saveSucceed" );
	}
	
	private function saveFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Inventory.saveFailed - MAY BE (error #2032)  The method SaveObjectChanges can only be called when connected to a game", Log.ERROR );
	}
	
	private function createFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_INVENTORY_TABLE != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Inventory.createFailed - Failed to create new Inventory object for this avatar.", Log.ERROR );
	}
}
}
