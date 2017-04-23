/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {

import com.voxelengine.GUI.voxelModels.PopupMetadataAndModelInfo;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.events.ModelBaseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;
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
	private var _name:Label
	private var _bpValue:Image
	private var _editData:Image
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

		_name = new Label( "", $widthParam );
		_name.fontColor = 0xffffff;
		_name.textAlign = TextAlign.CENTER
		//_count.x = 16;
		_name.y = 90;
		addElement(_count);
		addElement(_name);
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
		_name.text = "";

		switch ( $item.objectType ) {
		case ObjectInfo.OBJECTINFO_EMPTY:
			backgroundTexture = $item.backgroundTexture( width );
			setHelp( "Empty" );
			_count.text = "";
			break;
		case ObjectInfo.OBJECTINFO_MODEL:
			var om:ObjectModel = _objectInfo as ObjectModel;
			if ( om.vmm ) {
				if ( om.vmm.thumbnailLoaded && om.vmm.thumbnail ) {
					backgroundTexture = drawScaled( om.vmm.thumbnail, width, height );
//					var bmpd:BitmapData = Renderer.renderer.modelShot();
//					om.vmm.thumbnail = drawScaled( bmpd, width, height );
				}
				else
					ModelMetadataEvent.addListener( ModelMetadataEvent.BITMAP_LOADED, thumbnailLoaded )				
				
				// listen for changes to this object
				ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged )
				_name.text = om.vmm.name;
				var modelsOfThisGuid:int = om.vmm.permissions.copyCount;
				if ( 99999 < modelsOfThisGuid )
					_count.text = "lots";
				else if ( -1 == modelsOfThisGuid )
					_count.text = "∞";
				else
					_count.text = String( modelsOfThisGuid );

				setHelp( "guid: " + om.vmm.guid );

				if ( om.vmm.permissions.blueprint ) {
					_bpValue = new Image( Globals.texturePath + "blueprint.png" );
					if ( 128 == width )
						_bpValue.x = _bpValue.y = 64;
					addElement( _bpValue )
				}
				else if ( _bpValue ) {
					removeElement( _bpValue );
					_bpValue = null
				}

				if ( om.vmm.permissions.creator == Network.userId ) {
					_editData = new Image( Globals.texturePath + "editModelData.png" );
					$evtColl.addEvent( _editData, UIMouseEvent.CLICK, editModelData );
					if ( 128 == width )
						_editData.x = _editData.y = 0;
					addElement( _editData )
				} else if ( _editData ) {
					removeElement( _editData );
					_editData = null;
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

		function editModelData( $me:UIMouseEvent ):void {
			var t:ObjectModel = _objectInfo as ObjectModel;
			var vmm:ModelMetadata = t.vmm;
			if ( !PopupMetadataAndModelInfo.inExistance )
				new PopupMetadataAndModelInfo( vmm );
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
}
}