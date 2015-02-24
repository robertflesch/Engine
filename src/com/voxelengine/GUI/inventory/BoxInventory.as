/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {
	
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.MetadataManager;
import com.voxelengine.worldmodel.models.VoxelModelMetadata;


public class BoxInventory extends VVBox
{
	private var _count:Label
	private var _objectInfo:ObjectInfo;
	public function get objectInfo():ObjectInfo { return _objectInfo; }
	
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE, $item:ObjectInfo = null )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		autoSize = false;
		dragEnabled = true;
		data = $item;
		_count = new Label( "", $widthParam );
		_count.fontColor = 0xffffff;
		_count.textAlign = TextAlign.CENTER
		//_count.x = 16;
		_count.y = 20;
		addElement(_count);
		
		updateObjectInfo( $item );
	}	
	
	public function updateObjectInfo( $item:ObjectInfo ):void {
		if ( null == $item )
			return;
			
		_objectInfo = $item;
		data = $item;
		
		switch ( $item.objectType ) {
		case ObjectInfo.OBJECTINFO_EMPTY:
			backgroundTexture = "assets/textures/blank.png";
			setHelp( "" );			
			break;
		case ObjectInfo.OBJECTINFO_MODEL:
			with ( $item as ObjectModel ) {
				if ( null != $item.guid && "" != $item.guid ) {
					InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, modelCount ) ;
					InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_COUNT_REQUEST, Network.userId, $item.guid, -1 ) );
					
					if ( MetadataManager.metadataGet( $item.guid ) )
						updateObjectDisplayData( MetadataManager.metadataGet( $item.guid ) );	
					else {
						MetadataManager.addListener( ModelMetadataEvent.INFO_TEMPLATE_REPO, metadataRetrived );
						return;
					}
				}
				else {
					backgroundTexture = "assets/textures/NoImage128.png";
				}
			}
			break;
		case ObjectInfo.OBJECTINFO_ACTION:
			var oa:ObjectAction = $item as ObjectAction;
			backgroundTexture = "assets/textures/" + oa.image;
			setHelp( oa.name );			
			break;
		case ObjectInfo.OBJECTINFO_TOOL:
			var ot:ObjectTool = $item as ObjectTool;
			backgroundTexture = "assets/textures/" + ot.image;
			setHelp( ot.name );			
			break;
		case ObjectInfo.OBJECTINFO_VOXEL:
		default:
			var typeId:int;
			if ( $item is TypeInfo )
				typeId = ($item as TypeInfo).type;
			else
				typeId = ($item as ObjectVoxel).type;
			
			var typeInfo:TypeInfo = TypeInfo.typeInfo[typeId];
			if ( typeInfo ) {
				backgroundTexture = "assets/textures/" + typeInfo.image;
				setHelp( typeInfo.name );			
				
				InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
				InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST, Network.userId, typeId, -1 ) );
			}
			else
				Log.out( "BoxInventory.updateObjectInfo typeInfo not found for typeId: " + typeId );

			break;
		}
	}
	
	private function metadataRetrived(e:ModelMetadataEvent):void 
	{
		if ( e.guid == ( _objectInfo as ObjectModel ).guid )
			updateObjectDisplayData( e.vmm );	
	}
	
	private function updateObjectDisplayData( $vmm:VoxelModelMetadata ):void {
		Log.out( "BoxInventory.updateOBjectDisplayData vmm: " + $vmm.toString() );
		if ( null == $vmm.image ) {
			var bmpd:BitmapData = Globals.g_renderer.modelShot();
			$vmm.image = drawScaled( bmpd, bmpd.width, bmpd.height );
		}
		
		setHelp( $vmm.name );			
		backgroundTexture = $vmm.image;
	}
	
	private function modelCount(e:InventoryModelEvent):void 
	{
		if ( e.itemGuid == ( _objectInfo as ObjectModel ).guid ) {
			var modelsOfThisGuid:String = String( e.result.toFixed(0) );
			if ( 8 < modelsOfThisGuid.length )
				_count.text = "LOTS";
			else
				_count.text = modelsOfThisGuid;
		}
	}
	
	private function voxelCount(e:InventoryVoxelEvent):void 
	{
		var typeId:int;
		if ( _objectInfo is TypeInfo )
			typeId = (_objectInfo as TypeInfo).type;
		else
			typeId = (_objectInfo as ObjectVoxel).type;
			
		var ti:TypeInfo = TypeInfo.typeInfo[typeId];
		if ( ti.type == e.typeId ) {
			var totalOxelsOfThisTypeCount:Number = e.result / 4096;
			var totalOxelsOfThisType:String = String( totalOxelsOfThisTypeCount.toFixed(0) );
			_count.fontColor = ti.countColor;
			if ( totalOxelsOfThisTypeCount < 1 )
				_count.text = "< 1";
			else if ( 8 < totalOxelsOfThisType.length ) {
				_count.text = "LOTS";
			}
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
	
	public function reset():void {
		InventoryManager.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
		InventoryManager.removeListener( InventoryModelEvent.INVENTORY_MODEL_COUNT_RESULT, modelCount ) ;
		_count.text = "";
		backgroundTexture = "assets/textures/blank.png";
		data = null;
	}
	
	public function drawScaled(obj:BitmapData, srcWidth:int, srcHeight:int):BitmapData {
		var m:Matrix = new Matrix();
		m.scale(width/srcWidth, height/srcHeight);
		var bmpd:BitmapData = new BitmapData(width, height, false);
		bmpd.draw(obj, m);
		return bmpd;
	}	
	
}	

}