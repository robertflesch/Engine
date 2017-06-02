/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.PersistenceObject;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;


public class Inventory extends PersistenceObject
{
	// support data for persistence
	private var _generateNewInventory:Boolean;
	private var _loaded:Boolean;

	private var  _slots:Slots
	private var _voxels:Voxels;
	private var _characterSlots:CharacterSlots;
	public function get slots():Slots  { return _slots; }
	public function get voxels():Voxels  { return _voxels; }
	
	public function get loaded():Boolean { return _loaded; }
	public function set loaded($val:Boolean):void { _loaded = $val; }

	public function Inventory( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_INVENTORY );
		_slots = new Slots( this );
		_voxels = new Voxels( this );
		_characterSlots = new CharacterSlots( this );
//		ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
	}

//	private function childLoadingComplete( $mle:ModelLoadingEvent ):void {
//		_characterSlots.loadCharacterInventory();
//	}

	public function characterSlotGet( $slot:String ):String {
		return _characterSlots.items[$slot];
	}

	public function unload():void {
		//Log.out( "Inventory.unload - owner: " + guid, Log.WARN );
		_slots.unload();
		_voxels.unload();
		_characterSlots.unload();
	}
		
	public function deleteInventory():void {
		
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid, null ) );
		_slots = null;
		_voxels = null;
		_characterSlots = null;
	}

	//////////////////////////////////////////////////////////////////
	// Persistence
	//////////////////////////////////////////////////////////////////
	
	override public function save():Boolean {
		if ( !loaded ) {
			Log.out( "Inventory.save - Not LOADED - guid: " + guid, Log.DEBUG );
			return false;
		}

		if ( !changed || !Globals.online || doNotPersist ) {
	//			if ( Globals.online && !changed )
	//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT changed" );
	//			else if ( !Globals.online && changed )
	//				Log.out( name + " save - Not saving data - guid: " + guid + " NOT online" );
	//			else
	//				Log.out( name + " save - Not saving data - Offline and not changed" );
			return false;
		}

		// Network names are not valid guids, but we need to save them anyways!
		validatedSave();
		return true;
	}

	override protected function toObject():void {
		_slots.toObject( dbo );
		dbo.modifiedData = new Date().toUTCString()
		// voxels
		var ba:ByteArray = new ByteArray(); 
		ba.writeUTF( guid );
		_voxels.toByteArray( ba );
		ba.compress();
		dbo.voxelData = ba;
		_characterSlots.toObject( dbo );
	}

	public function fromObject( $dbo:DatabaseObject ):void {
		var isNewRecord:Boolean = false;
		if ( $dbo ) {
			dbo  = $dbo;
            _slots.fromObject( dbo );
		}
		else {
			super.assignNewDatabaseObject();
			isNewRecord = true;
            _slots.addSlotDefaultData();
		}
		
		// Slot data is stored as fields for easy analysis
		// we can know what user carry around

		if ( dbo && dbo.voxelData ) {
			var ba:ByteArray = dbo.voxelData;
			if ( ba && 0 < ba.bytesAvailable ) {
				try { ba.uncompress(); }
				catch (error:Error) {
					Log.out( "Inventory.fromObject - Was expecting compressed oxelPersistence " + guid, Log.WARN ); }
				ba.position = 0;

//				ba.uncompress();
				var ownerId:String = ba.readUTF();
				_voxels.fromObject( ba );
			}
		}
		else {
			var ownerModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( guid );
			if ( ownerModel && ownerModel == VoxelModel.controlledModel )
				_voxels.addTestData();
		}

		if ( $dbo ) {
			dbo  = $dbo;
			_characterSlots.fromObject( dbo );
		}
		else {
			super.assignNewDatabaseObject();
			isNewRecord = true;
			//_characterSlots.addSlotDefaultData();
		}

		if ( isNewRecord )
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, guid, null ) );
	}
	
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid ) );
		}
	}
	
	override protected function notFound($pe:PersistenceEvent):void
	{
		if ( table != $pe.table )
			return;
		// this occurs on first time logging in.
		removeLoadEvents();
		Log.out( "Inventory.notFound - OWNER: " + guid, Log.WARN );
		fromObject( null );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, guid, this ) );
	}
	
	override protected function loadSuccess( $pe:PersistenceEvent ):void
	{
		if ( table != $pe.table )
			return;
		if ( guid != $pe.guid )
			return;
		removeLoadEvents();
		fromObject( $pe.dbo );
		_loaded = true;
		//Log.out( "Inventory.loadSuccess - OWNER: " + guid + "  guid: " + $pe.guid, Log.WARN );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, guid, this ) );
	}
	
	override protected function loadFailed( $pe:PersistenceEvent ):void
	{
		if ( table != $pe.table )
			return;
		removeLoadEvents();
		(new Alert( "ERROR LOADING USER INVENTORY - Please post on forums" )).display();
	}
}
}
