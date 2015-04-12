/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import com.voxelengine.worldmodel.TypeInfo;
import flash.events.TimerEvent;
import flash.utils.Timer;

import com.voxelengine.Log;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.inventory.ObjectInfo;

/**
 * ...
 * @author Robert Flesch
 * Base class for the representation of edit cursor size selection
 */
public class ObjectVoxel extends ObjectInfo 
{
	private var _typeId:int;
	private var _count:int;
	public function get type():int { return _typeId; }
	public function get count():int { return _count; }

	public function ObjectVoxel( $owner:BoxInventory, $typeId:int ):void {
		super( $owner, ObjectInfo.OBJECTINFO_VOXEL );
		_typeId = $typeId;
		if ( 0 < _typeId )
			updateCount();
	}
	
	override public function backgroundTexture( size:int = 64 ):String { 
		var typeInfo:TypeInfo = TypeInfo.typeInfo[_typeId];
		if ( typeInfo )
			return "assets/textures/" + typeInfo.image;
			
		return "assets/textures/invalid.png";
	}
	
	
	override public function asInventoryString():String {
		return _objectType + ";" + _typeId;
	}
	
	override public function fromInventoryString( $data:String, $slotId:int ): ObjectInfo {
		super.fromInventoryString( $data, $slotId );
		var values:Array = $data.split(";");
		if ( values.length != 2 ) {
			Log.out( "TypeInfo.fromInventoryString - not equal to 4 tokens found, length is: " + values.length, Log.WARN );
			_objectType = ObjectInfo.OBJECTINFO_VOXEL;
			_typeId = 0;
			return this;
		}
		_objectType = ObjectInfo.OBJECTINFO_VOXEL;
		_typeId = values[1];
		delayedUpdateCount();
		return this;
	}
	
	private function delayedUpdateCount():void
	{
		var pt:Timer = new Timer( 100, 1 );
		pt.addEventListener(TimerEvent.TIMER, delayOver );
		pt.start();
	}

	private function delayOver(event:TimerEvent):void
	{
		updateCount();
	}
	
	private function updateCount():void {
		InventoryVoxelEvent.addListener( InventoryVoxelEvent.COUNT_RESULT, voxelCount ) ;
		InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.COUNT_REQUEST, Network.userId, _typeId, -1 ) );
	}

	private function voxelCount(e:InventoryVoxelEvent):void 
	{
		if ( e.typeId == _typeId ) {
			InventoryVoxelEvent.removeListener( InventoryVoxelEvent.COUNT_RESULT, voxelCount ) ;
			_count = e.result as int;
			if ( box )
				box.updateObjectInfo( this );
		}
	}
}
}