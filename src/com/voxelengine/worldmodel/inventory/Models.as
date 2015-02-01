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

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.InventoryModelEvent;

public class Models
{
	private var _networkId:String;
	private var _changed:Boolean;
	
	public function get changed():Boolean { return _changed; }
	public function set changed(value:Boolean):void  { _changed = value; }
	
	public function Models( $networkId:String ) {
		_networkId = $networkId;
		
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_INCREMENT,		modelChange );
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_DECREMENT, 		modelChange );
	}

	public function modelChange(e:InventoryModelEvent):void {
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {}
	public function toPersistance( $dbo:DatabaseObject ):void {}

	public function fromByteArray( $ba:ByteArray ):void {
	}
	public function asByteArray( $ba:ByteArray ):ByteArray { 
		return $ba; 
	}
	
	public function modelCount(e:InventoryModelEvent):void 
	{
		//var modelId:String = e.guid;
		//var modelCount:int = _models[modelId];
		//InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, _networkId, modelId, modelCount ) );
	}
	
	public function modelIncrement(e:InventoryModelEvent):void 
	{
		
	}
	
	public function modelDecrement(e:InventoryModelEvent):void 
	{
		
	}
}
}
