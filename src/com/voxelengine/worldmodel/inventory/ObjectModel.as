/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.worldmodel.models.ModelGuid;
import com.voxelengine.worldmodel.models.ModelInfo;

import flash.events.TimerEvent
import flash.utils.Timer

import com.voxelengine.Log
import com.voxelengine.events.InventorySlotEvent
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent
import com.voxelengine.GUI.inventory.BoxInventory
import com.voxelengine.server.Network

public class ObjectModel extends ObjectInfo
{
	private var _displayAddons:Boolean = true;
	protected var _modelGuid:ModelGuid = new ModelGuid();
	public function get modelGuid():String 						{ return _modelGuid.val; }
	public function set modelGuid(value:String):void 			{ _modelGuid.valSet = value; }

	protected var _mi:ModelInfo;
	public function get modelInfo():ModelInfo 					{ return _mi }
	public function set modelInfo(value:ModelInfo):void 		{ _mi = value }

	public function ObjectModel( $owner:BoxInventory, $guid:String ):void {
		super( $owner, ObjectInfo.OBJECTINFO_MODEL, "Left click to place model" );
		modelGuid = $guid;
	}
	
	override public function asInventoryString():String {
		if ( ObjectInfo.OBJECTINFO_MODEL == _objectType )
			return String( _objectType + ";" + modelGuid );

		return String( _objectType );
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId );
		var values:Array = $data.split(";");
		if ( values.length != 2 ) {
			Log.out( "ObjectModel.fromInventoryString - not equal to 2 tokens found, length is: " + values.length, Log.WARN );
			reset();
			return this
		}
		_objectType = values[0];
		modelGuid = values[1];
		_displayAddons = false;
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoAdded );
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );
		ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, modelGuid, null );
		return this
	}
	
	private function modelInfoFailed(e:ModelInfoEvent):void
	{
		if ( modelGuid == e.modelGuid ) {
            ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoAdded );
			ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );
			//_owner remove me!
			reset();
			if ( box )
				box.reset();
			Log.out( "ObjectModel.modelInfoFailed - guid: " + e.modelGuid, Log.WARN );
			InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, _slotId, new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME ) );
		}
	}
	
	private function modelInfoAdded(e:ModelInfoEvent):void
	{
		if ( modelGuid == e.modelGuid ) {
			ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoAdded );
			ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );
            _mi = e.modelInfo;
			_name = _mi.name;
			// a delay is needed since the modelInfo loads the thumbnail on a separate thread.
			delayedUpdate()
		}
	}
	
	private function delayedUpdate():void
	{
		var pt:Timer = new Timer( 2000, 1 );
		pt.addEventListener(TimerEvent.TIMER, delayOver );
		pt.start()
	}

	private function delayOver(event:TimerEvent):void
	{
		if ( box )
			box.updateObjectInfo( this, _displayAddons )
	}
	
	override public function reset():void {
		super.reset();
		_modelGuid.release();
		_modelGuid = null;
		_mi = null;
	}
}
}