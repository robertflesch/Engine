/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {

import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.ModelCache;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.*;


public class Inventory {
	private var _loaded:Boolean;
    public function get loaded():Boolean { return _loaded; }
    public function set loaded($val:Boolean):void { _loaded = $val; }

    private var _dbo:DatabaseObject;
	private var  _slots:Slots;
    public function get slots():Slots  { return _slots; }
	private var _voxels:Voxels;
    public function get voxels():Voxels  { return _voxels; }

	private var _characterSlots:CharacterSlots;

    private var _ownerGuid:String;
    public function get ownerGuid() :String { return _ownerGuid; }


	public function Inventory( $ie:InventoryEvent ) {
        _ownerGuid = $ie.owner;
		_dbo = $ie.result; // in this case I am passing the dbo of the the players PlayerObjects
		_slots = new Slots( this );
		_voxels = new Voxels( this );
		_characterSlots = new CharacterSlots( this );
		fromObject();
	}

	public function set changed($val:Boolean):void {
		toObject();
		var p:Player = Player.player;
		p.changed = $val;
	}

	public function characterSlotGet( $slot:String ):String {
		return _characterSlots.items[$slot];
	}

	public function unload():void {
		//Log.out( "Inventory.unload - owningModel: " + guid, Log.WARN );
		_slots.unload();
		_voxels.unload();
		_characterSlots.unload();
	}
		
	public function deleteInventory():void {
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_INVENTORY, _ownerGuid, null ) );
		_slots = null;
		_voxels = null;
		_characterSlots = null;
	}

	//////////////////////////////////////////////////////////////////
	// Persistence
	//////////////////////////////////////////////////////////////////
	
	public function toObject():void {
		_slots.toObject( _dbo.inventory );
//        _dbo.modifiedData = new Date().toUTCString();
		// voxels
		var ba:ByteArray = new ByteArray(); 
		ba.writeUTF( _ownerGuid );
		_voxels.toByteArray( ba );
		ba.compress();
        _dbo.inventory.voxelData = ba;
		_characterSlots.toObject( _dbo.inventory );
	}

	public function fromObject():void {
		if ( _dbo.inventory ) {
			// Slot data is stored as fields for easy analysis
			// we can know what user carry around
            _slots.fromObject( _dbo.inventory );
			_characterSlots.fromObject( _dbo.inventory );

			var ba:ByteArray = _dbo.inventory.voxelData;
			if ( ba && 0 < ba.bytesAvailable ) {
				try { ba.uncompress(); }
				catch (error:Error) {
					Log.out( "Inventory.fromObject - Was expecting compressed oxelPersistence " + _ownerGuid, Log.WARN ); }
				ba.position = 0;

				// have to read it!
				// TODO should version it!
				var ownerId:String = ba.readUTF();
				_voxels.fromObject( ba );
				loaded = true;
			}
		}
		else {
            _dbo.inventory = {};
//			var ownerModel:VoxelModel = Region.currentRegion.modelCache.instanceGet( _ownerGuid );
//			if ( ownerModel && ownerModel == VoxelModel.controlledModel )
			_voxels.addTestData();
			_characterSlots.addDefaultData();
            _slots.addDefaultData();
			toObject();
            Player.player.changed = true;
            InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.SAVE_REQUEST, _ownerGuid, this ) );
		}
	}
}
}
