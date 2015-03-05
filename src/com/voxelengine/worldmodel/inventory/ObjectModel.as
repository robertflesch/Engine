/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectModel extends ObjectInfo 
{
	protected var _guid:String 				= null;
	protected var _vmm:ModelMetadata;
	
	public function get guid():String 						{ return _guid; }
	public function set guid(value:String):void 			{ _guid = value; }
	
	public function get vmm():ModelMetadata { return _vmm; }
	public function set vmm(value:ModelMetadata):void { _vmm = value; }
	
	public function ObjectModel( $owner:BoxInventory, $guid:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_MODEL );
		_guid = $guid;
	}
	
	override public function asInventoryString():String {
		if ( ObjectInfo.OBJECTINFO_MODEL == _objectType )
			return String( _objectType + ";" + _guid );
			
		return String( _objectType );	
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId );
		var values:Array = $data.split(";");
		if ( values.length != 2 ) {
			Log.out( "ObjectModel.fromInventoryString - not equal to 2 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this;
		}
		_objectType = values[0];
		_guid = values[1];
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, metadataAdded );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, metadataAdded );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, _guid, null ) );
		return this;
	}
	
	private function metadataFailed(e:ModelMetadataEvent):void 
	{
		if ( _guid == e.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, metadataAdded );
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed );
			//_owner remove me!
			reset();
			if ( box )
				box.reset();
			Log.out( "ObjectModel.metadataFailed - guid: " + e.guid, Log.WARN );
			InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, _slotId, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) ) );
		}
	}
	
	private function metadataAdded(e:ModelMetadataEvent):void 
	{
		if ( _guid == e.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, metadataAdded );
			ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, metadataAdded );
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed );
			_vmm = e.vmm;
			if ( box )
				box.updateObjectInfo( this );
		}
	}
	
	override public function reset():void {
		super.reset();
		_guid = null;
		_vmm = null;
	}
}
}