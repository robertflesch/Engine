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
	private var _bpValue:Image	
	private var _objectInfo:ObjectInfo;
	public function get objectInfo():ObjectInfo { return _objectInfo; }
	
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		padding = 0
		autoSize = false;
		dragEnabled = true;
		_count = new Label( "", $widthParam );
		_count.fontColor = 0xffffff;
		_count.textAlign = TextAlign.CENTER
		//_count.x = 16;
		_count.y = 20;
		addElement(_count);
	}	
	
	private function thumbnailLoaded( $mme:ModelMetadataEvent ):void {
		var om:ObjectModel = _objectInfo as ObjectModel
		if ( $mme.modelGuid == om.modelGuid ) {
			ModelMetadataEvent.removeListener( ModelMetadataEvent.BITMAP_LOADED, thumbnailLoaded )				
			backgroundTexture = drawScaled( om.vmm.thumbnail, width, height );
		}
	}
	
	private function metadataChanged( $mme:ModelMetadataEvent ):void {
		var om:ObjectModel = _objectInfo as ObjectModel
		if ( om && ( $mme.modelGuid == om.modelGuid ) ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.CHANGED, metadataChanged )
			om.vmm = $mme.modelMetadata
			updateObjectInfo( om )
		}
	}
	
	
	public function updateObjectInfo( $item:ObjectInfo ):void {
		if ( null == $item )
			return;
			
		_objectInfo = $item;
		data = $item;
		
		switch ( $item.objectType ) {
		case ObjectInfo.OBJECTINFO_EMPTY:
			backgroundTexture = $item.backgroundTexture( width );
			setHelp( "Empty" );		
			_count.text = "";
			break;
		case ObjectInfo.OBJECTINFO_MODEL:
			var om:ObjectModel = _objectInfo as ObjectModel;
			if ( om.vmm ) {
				if ( om.vmm.thumbnailLoaded ) {
					backgroundTexture = drawScaled( om.vmm.thumbnail, width, height );
//					var bmpd:BitmapData = Globals.g_renderer.modelShot();
//					om.vmm.thumbnail = drawScaled( bmpd, width, height );
				}
				else
					ModelMetadataEvent.addListener( ModelMetadataEvent.BITMAP_LOADED, thumbnailLoaded )				
				
				// listen for changes to this object
				ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged )
				
				var modelsOfThisGuid:int = om.vmm.permissions.copyCount;
				if ( 99999 < modelsOfThisGuid )
					_count.text = "lots";
				else if ( -1 == modelsOfThisGuid )
					_count.text = "∞";
				else
					_count.text = String( modelsOfThisGuid );

				setHelp( om.vmm.name );			
				if ( om.vmm.permissions.blueprint ) {
					_bpValue = new Image( Globals.texturePath + "blueprint.png" )
					if ( 128 == width )
						_bpValue.x = _bpValue.y = 64
					addElement( _bpValue )
				}
				else if ( _bpValue ) {
					removeElement( _bpValue )
					_bpValue = null
				}
			}
			break;
			
		case ObjectInfo.OBJECTINFO_ACTION:
			var oa:ObjectAction = $item as ObjectAction;
			backgroundTexture = $item.backgroundTexture( width );
			setHelp( oa.name );
			_count.text = "";
			break;
			
		case ObjectInfo.OBJECTINFO_TOOL:
			var ot:ObjectTool = $item as ObjectTool;
			backgroundTexture = $item.backgroundTexture( width );
			setHelp( ot.name );			
			_count.text = "";
			break;
			
		case ObjectInfo.OBJECTINFO_VOXEL:
		default:
			var ov:ObjectVoxel = $item as ObjectVoxel;
			var typeId:int = ov.type;
			
			var typeInfo:TypeInfo = TypeInfo.typeInfo[typeId];
			if ( typeInfo ) {
				backgroundTexture = $item.backgroundTexture( width );
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
				_count.text = "lots";
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
		if ( _bpValue ) {
			removeElement( _bpValue )
			_bpValue = null
		}

		_objectInfo = new ObjectInfo( this, ObjectInfo.OBJECTINFO_EMPTY );
	}
	
	private function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
		var m:Matrix = new Matrix();
		m.scale(destWidth/obj.width, destHeight/obj.height);
		var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
		bmpd.draw(obj, m);
		return bmpd;
	}	
	
	
}	

}