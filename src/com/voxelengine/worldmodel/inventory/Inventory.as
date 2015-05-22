/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	
import com.voxelengine.worldmodel.models.PersistanceObject;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import org.flashapi.swing.Alert;
	
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.*;
import com.voxelengine.worldmodel.inventory.ObjectInfo;


public class Inventory extends PersistanceObject
{
	// support data for persistance
	private var _createdDate:Date;
	private var _modifiedDate:Date;
	private var _generateNewInventory:Boolean;
	private var _loaded:Boolean;

	private var  _slots:Slots
	private var _voxels:Voxels;
	public function get slots():Slots  { return _slots; }
	public function get voxels():Voxels  { return _voxels; }
	
	public function get loaded():Boolean { return _loaded; }
	
	public function Inventory( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_INVENTORY );
		_slots = new Slots( $guid );
		_voxels = new Voxels( $guid );
	}
	
	public function unload():void {
		//Log.out( "Inventory.unload - owner: " + guid, Log.WARN );
		_slots.unload();
		_voxels.unload();
	}
		
	private function changed():Boolean {
		if ( _slots.changed || _voxels.changed )
			return true;
		return false;
	}
	
	public function deleteInventory():void {
		
		PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid, null ) );
		_slots = null;
		_voxels = null;
	}

	
	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	override protected function toObject():Object {
		var ba:ByteArray = new ByteArray();	
		var obj:Object = new Object();
		obj.ba = asByteArray( ba );
		return obj;
	}
	
	override protected function toPersistance():void {
		_voxels.toPersistance(_dbo);
		_slots.toPersistance(_dbo);
		var ba:ByteArray = new ByteArray(); 
		_dbo.data 			= asByteArray( ba );
	}

	private function asByteArray( $ba:ByteArray ):ByteArray {
		$ba.writeUTF( guid );
		_voxels.asByteArray( $ba );
		_slots.asByteArray( $ba );
		$ba.compress();
		return $ba;	
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid ) );
		}
	}

	// If $dbo is null then the default data is loaded
	override public function fromPersistance( $dbo:DatabaseObject ):void {
		
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
			var ownerModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( guid );
			if ( ownerModel && ownerModel is Player )
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
		if ( Globals.BIGDB_TABLE_INVENTORY != $pe.table )
			return;
		// this occurs on first time logging in.
		removeLoadEvents();
		Log.out( "Inventory.notFound - OWNER: " + guid, Log.WARN );
		fromPersistance( null );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, guid, this ) );
	}
	
	private function loadSuccess( $pe:PersistanceEvent ):void
	{
		if ( Globals.BIGDB_TABLE_INVENTORY != $pe.table )
			return;
		if ( guid != $pe.guid )
			return;
		removeLoadEvents();
		fromPersistance( $pe.dbo );
		_loaded = true;
		Log.out( "Inventory.loadSuccess - OWNER: " + guid + "  guid: " + $pe.guid, Log.WARN );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, guid, this ) );
	}
	
	private function loadFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.BIGDB_TABLE_INVENTORY != $pe.table )
			return;
		removeLoadEvents();
		(new Alert( "ERROR LOADING USER INVENTORY - Please post on forums" )).display();
	}
}
}
