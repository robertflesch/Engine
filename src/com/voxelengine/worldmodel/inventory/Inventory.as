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
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.PersistanceObject;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;


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
		_slots = new Slots( this );
		_voxels = new Voxels( this );
	}
	
	public function unload():void {
		//Log.out( "Inventory.unload - owner: " + guid, Log.WARN );
		_slots.unload();
		_voxels.unload();
	}
		
	public function deleteInventory():void {
		
		PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid, null ) );
		_slots = null;
		_voxels = null;
	}

	//////////////////////////////////////////////////////////////////
	// Persistance
	//////////////////////////////////////////////////////////////////
	
	override public function save():void {
		// TODO this needs to detect "changed"
		if ( !loaded ) {
			Log.out( "Inventory.save - Not LOADED - guid: " + guid, Log.DEBUG );
			return; 
		}
		Log.out( "Inventory.save - saving - guid: " + guid, Log.DEBUG );
		super.save();
	}
	
	override protected function toObject():void {
		_slots.toObject(dbo);
		
		// voxels
		var ba:ByteArray = new ByteArray(); 
		ba.writeUTF( guid );
		_voxels.toByteArray( ba );
		ba.compress();
		dbo.data = ba;	
	}


	public function fromObject( $dbo:DatabaseObject ):void {
		
		if ( $dbo ) {
			_createdDate	= $dbo.createdDate;
			_modifiedDate   = $dbo.modifiedDate;
			dbo 			= $dbo;
		}
		
		// Slot data is stored as fields for easy analysis
		// we can know what user carry around
		_slots.fromObject( $dbo );
		
		if ( $dbo && $dbo.data ) {
			var ba:ByteArray = $dbo.data 
			if ( ba && 0 < ba.bytesAvailable ) {
				ba.uncompress();
				var ownerId:String = ba.readUTF();
				_voxels.fromObject( ba );
			}
		}
		else {
			var ownerModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( guid );
			if ( ownerModel && ownerModel is Player )
				_voxels.addTestData();
		}
	}
	
	public function load():void {
		if ( Globals.online ) {
			addLoadEvents();
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, guid ) );
		}
	}
	
	override protected function notFound($pe:PersistanceEvent):void 
	{
		if ( table != $pe.table )
			return;
		// this occurs on first time logging in.
		removeLoadEvents();
		Log.out( "Inventory.notFound - OWNER: " + guid, Log.WARN );
		fromObject( null );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.RESPONSE, guid, this ) );
	}
	
	override protected function loadSuccess( $pe:PersistanceEvent ):void
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
	
	override protected function loadFailed( $pe:PersistanceEvent ):void
	{
		if ( table != $pe.table )
			return;
		removeLoadEvents();
		(new Alert( "ERROR LOADING USER INVENTORY - Please post on forums" )).display();
	}
}
}
