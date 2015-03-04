/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {
	
import com.voxelengine.events.ModelBaseEvent;
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
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.ModelMetadataCache;
import com.voxelengine.worldmodel.models.ModelMetadata;


public class BoxInventory extends VVBox
{
	private var _count:Label
	private var _objectInfo:ObjectInfo;
	public function get objectInfo():ObjectInfo { return _objectInfo; }
	
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		autoSize = false;
		dragEnabled = true;
		_count = new Label( "", $widthParam );
		_count.fontColor = 0xffffff;
		_count.textAlign = TextAlign.CENTER
		//_count.x = 16;
		_count.y = 20;
		addElement(_count);
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
			var om:ObjectModel = _objectInfo as ObjectModel;
			if ( om.vmm ) {
				if ( null == om.vmm.thumbnail ) {
					var bmpd:BitmapData = Globals.g_renderer.modelShot();
					om.vmm.thumbnail = drawScaled( bmpd, bmpd.width, bmpd.height );
				}
				
				//var modelsOfThisGuid:String = String( e.result.toFixed(0) );
				var modelsOfThisGuid:int = om.vmm.copyCount;
				if ( 99999 < modelsOfThisGuid )
					_count.text = "LOTS";
				else if ( -1 == modelsOfThisGuid )
					_count.text = "∞";
				else
					_count.text = String( modelsOfThisGuid );
					
				setHelp( om.vmm.name );			
				backgroundTexture = om.vmm.thumbnail;
			}
			break;
		case ObjectInfo.OBJECTINFO_ACTION:
			var oa:ObjectAction = $item as ObjectAction;
			backgroundTexture = "assets/textures/" + oa.thumbnail;
			setHelp( oa.name );			
			break;
		case ObjectInfo.OBJECTINFO_TOOL:
			var ot:ObjectTool = $item as ObjectTool;
			backgroundTexture = "assets/textures/" + ot.thumbnail;
			setHelp( ot.name );			
			break;
		case ObjectInfo.OBJECTINFO_VOXEL:
		default:
			if ( $item is TypeInfo ) {
				throw new Error( "BoxInventory.updateObjectInfo - Deprecated type", Log.ERROR );
				return;
			}
			var ov:ObjectVoxel = $item as ObjectVoxel;
			var typeId:int = ov.type;
			
			var typeInfo:TypeInfo = TypeInfo.typeInfo[typeId];
			if ( typeInfo ) {
				backgroundTexture = "assets/textures/" + typeInfo.image;
				setHelp( typeInfo.name );			
			}
			else {
				throw new Error( "BoxInventory.updateObjectInfo typeInfo not found for typeId: " + typeId, Log.ERROR );
				return;
			}

			var totalOxelsOfThisTypeCount:Number = ov.count / 4096;
			var totalOxelsOfThisType:String = String( totalOxelsOfThisTypeCount.toFixed(0) );
			_count.fontColor = typeInfo.countColor;
			if ( totalOxelsOfThisTypeCount < 1 )
				_count.text = "< 1";
			else if ( -1 == totalOxelsOfThisTypeCount )
				_count.text = "∞";
			else if ( 8 < totalOxelsOfThisType.length ) {
				_count.text = "LOTS";
			}
			else
				_count.text = totalOxelsOfThisType;
				
			break;
		}
	}
	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
		// while it is active we want to monitor the count of oxels as they change
	}
	
	public function reset():void {
		_count.text = "";
		backgroundTexture = "assets/textures/blank.png";
		data = null;
		_objectInfo = new ObjectInfo( this, ObjectInfo.OBJECTINFO_EMPTY );
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