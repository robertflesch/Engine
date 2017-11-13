/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {


import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.GUI.voxelModels.PopupModelInfo;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.PermissionsModel;
import com.voxelengine.worldmodel.TextureBank;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.Role;
import com.voxelengine.worldmodel.models.types.Player;

public class BoxInventory extends VVBox
{
	private var _count:Label;
	private var _name:Label;
	private var _bpValue:Image;
	private var _editData:Image;
	private var _objectInfo:ObjectInfo;
	public function get objectInfo():ObjectInfo { return _objectInfo; }
	
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		padding = 0;
		autoSize = false;
		dragEnabled = true;
		_count = new Label( "", $widthParam );
		_count.fontColor = 0xffffff;
		_count.textAlign = TextAlign.CENTER;
		//_count.x = 16;
		_count.y = 5;

		_name = new Label( "", $widthParam );
		_name.fontColor = 0xffffff;
        _name.fontSize = _name.fontSize + 1;
		_name.textAlign = TextAlign.CENTER;
		//_count.x = 16;
		_name.y = 105;
		addElement(_count);
		addElement(_name);
	}
	
	private function thumbnailLoaded( $mme:ModelInfoEvent ):void {
        var om:ObjectModel = _objectInfo as ObjectModel;
		if ( $mme.modelGuid == om.modelGuid ) {
			ModelInfoEvent.removeListener( ModelInfoEvent.BITMAP_LOADED, thumbnailLoaded );
			backgroundTexture = drawScaled( om.modelInfo.thumbnail, width, height );
		}
	}

	private function metadataChanged( $mme:ModelInfoEvent ):void {
		var om:ObjectModel = _objectInfo as ObjectModel;
		if ( om && ( $mme.modelGuid == om.modelGuid ) ) {
			updateObjectInfo( om )
		}
	}
	
	
	public function updateObjectInfo( $item:ObjectInfo, $displayAddons:Boolean = true ):void {
        // this may or may not have this event registered, but we need to make sure its not in more than one.
		ModelInfoEvent.removeListener( ModelBaseEvent.UPDATE, metadataChanged );
		if ( null == $item )
			return;
			
		_objectInfo = $item;
		data = $item;
		_name.text = "";

        var role:Role = Player.player.role;
        //if ( role.modelNominate && role.modelPromote ) {

            switch ( $item.objectType ) {
		case ObjectInfo.OBJECTINFO_EMPTY:
			reset();
            backgroundTexture = $item.backgroundTexture(width);
            break;
		case ObjectInfo.OBJECTINFO_MODEL:
			var om:ObjectModel = _objectInfo as ObjectModel;
			if ( om.modelInfo ) {
				if ( om.modelInfo.thumbnailLoaded && om.modelInfo.thumbnail )
					backgroundTexture = drawScaled( om.modelInfo.thumbnail, width, height );
				else
					ModelInfoEvent.addListener( ModelInfoEvent.BITMAP_LOADED, thumbnailLoaded );
				
				// listen for changes to this object
				ModelInfoEvent.addListener( ModelBaseEvent.UPDATE, metadataChanged );

				_name.text = om.modelInfo.name;
				var permissions:PermissionsModel = om.modelInfo.permissions;
				var modelsOfThisGuid:int = permissions.copyCount;
				if ( 99999 < modelsOfThisGuid )
					_count.text = "lots";
				else if ( -1 == modelsOfThisGuid )
					_count.text = "∞";
				else
					_count.text = String( modelsOfThisGuid );

				setHelp( "guid: " + om.modelInfo.guid );

				if ( $displayAddons&& permissions.creator == Network.userId || role.modelPublicEdit ) {
					_editData = new Image( "editModelData.png", 40, 40, true);
					$evtColl.addEvent(_editData, UIMouseEvent.CLICK, editModelData);
					if (128 == width)
						_editData.x = _editData.y = 0;
					addElement(_editData)
				} else if (_editData) {
					removeElement(_editData);
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
            if ( _editData ) {
                removeElement(_editData);
                _editData = null;
            }
            else if (_bpValue) {
                removeElement(_bpValue);
                _bpValue = null
            }

			_name.text = "";
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
			var modelInfo:ModelInfo = t.modelInfo;
			if ( modelInfo && !PopupModelInfo.inExistance )
				new PopupModelInfo( modelInfo );
		}
	}

	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
		// while it is active we want to monitor the count of oxels as they change
	}
	
	public function reset():void {
		setHelp( "Empty" );
		_count.text = "";
		backgroundTexture = TextureBank.BLANK_IMAGE;
		data = null;
		if ( _bpValue ) {
			removeElement( _bpValue );
			_bpValue = null
		}
		if ( _editData ) {
			removeElement( _editData );
			_editData = null
		}

		_objectInfo = new ObjectInfo( this, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME );
	}
}
}