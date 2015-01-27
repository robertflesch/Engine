/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {
	
import com.voxelengine.worldmodel.inventory.InventoryManager;
import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.ObjectInfo;


public class BoxInventory extends VVBox
{
	private var _count:Label
	private var _objectInfo:ObjectInfo;
	
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE, $item:ObjectInfo = null )
	{
		super( $widthParam, $heightParam, $borderStyle, ($item ? $item.name : "") );
		layout = new AbsoluteLayout();
		autoSize = false;
		dragEnabled = true;
		data = $item;
		
		updateObjectInfo( $item );
	}	
	
	public function updateObjectInfo( $item:ObjectInfo ):void {
		if ( null == $item )
			return;
			
		_objectInfo = $item;
		backgroundTexture = "assets/textures/" + $item.image;
		
		_count = new Label( "", 64 );
		_count.fontColor = 0xffffff;
		_count.textAlign = TextAlign.CENTER
		//_count.x = 16;
		_count.y = 20;
		addElement(_count);
		
		if ( $item is TypeInfo ) {
			InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
			InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST, Network.userId, ($item as TypeInfo).type, -1 ) );
		}
		else if ( $item is ObjectInfo )  {
			InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, modelCount ) ;
			InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_REQUEST, Network.userId, $item.guid, -1 ) );
		}
	}
	
	private function modelCount(e:InventoryModelEvent):void 
	{
		if ( _objectInfo.guid == e.itemGuid ) {
			var modelsOfThisGuid:String = String( e.count );
			if ( 8 < modelsOfThisGuid.length )
				_count.text = "LOTS";
			else
				_count.text = modelsOfThisGuid;
		}
		
	}
	
	private function voxelCount(e:InventoryVoxelEvent):void 
	{
		if ( (_objectInfo as TypeInfo).type == e.typeId ) {
			var totalOxelsOfThisType:String = String( e.result );
			if ( 8 < totalOxelsOfThisType.length )
				_count.text = "LOTS";
			else
				_count.text = totalOxelsOfThisType;
		}
	}
	
	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
		// while it is active we want to monitor the count of oxels as they change
		InventoryManager.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
		InventoryManager.removeListener( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, modelCount ) ;
	}
}	
}