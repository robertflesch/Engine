/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import flash.events.TimerEvent
import flash.utils.Timer

import com.voxelengine.Log
import com.voxelengine.events.InventorySlotEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.GUI.inventory.BoxInventory
import com.voxelengine.server.Network
import com.voxelengine.worldmodel.inventory.ObjectInfo
import com.voxelengine.worldmodel.models.ModelMetadata

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectModel extends ObjectInfo 
{
	protected var _modelGuid:String
	protected var _vmm:ModelMetadata
	
	public function get modelGuid():String 						{ return _modelGuid }
	public function set modelGuid(value:String):void 			{ _modelGuid = value }
	
	public function get vmm():ModelMetadata 					{ return _vmm }
	public function set vmm(value:ModelMetadata):void 			{ _vmm = value }
	
	public function ObjectModel( $owner:BoxInventory, $guid:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_MODEL )
		_modelGuid = $guid
	}
	
	override public function asInventoryString():String {
		if ( ObjectInfo.OBJECTINFO_MODEL == _objectType )
			return String( _objectType + "" + _modelGuid )
			
		return String( _objectType )	
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId )
		var values:Array = $data.split("")
		if ( values.length != 2 ) {
			Log.out( "ObjectModel.fromInventoryString - not equal to 2 tokens found, length is: " + values.length, Log.WARN )
			reset()
			return this
		}
		_objectType = values[0]
		_modelGuid = values[1]
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, metadataAdded )
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, metadataAdded )
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed )
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) )
		return this
	}
	
	private function metadataFailed(e:ModelMetadataEvent):void 
	{
		if ( _modelGuid == e.modelGuid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, metadataAdded )
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed )
			//_owner remove me!
			reset()
			if ( box )
				box.reset()
			Log.out( "ObjectModel.metadataFailed - guid: " + e.modelGuid, Log.WARN )
			InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, Network.userId, _slotId, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY ) ) )
		}
	}
	
	private function metadataAdded(e:ModelMetadataEvent):void 
	{
		if ( _modelGuid == e.modelGuid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, metadataAdded )
			ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, metadataAdded )
			ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, metadataFailed )
			_vmm = e.modelMetadata
			// a delay is needed since the metadata loads the thumbnail on a seperate thread.
			delayedUpdate()
		}
	}
	
	private function delayedUpdate():void
	{
		var pt:Timer = new Timer( 2000, 1 )
		pt.addEventListener(TimerEvent.TIMER, delayOver )
		pt.start()
	}

	private function delayOver(event:TimerEvent):void
	{
		if ( box )
			box.updateObjectInfo( this )
	}
	
	override public function reset():void {
		super.reset()
		_modelGuid = null
		_vmm = null
	}
}
}