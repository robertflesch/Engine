/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {


import com.voxelengine.Globals;
import com.voxelengine.events.InventoryVoxelEvent;

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
	protected var _countLabel:Label;
    protected var _nameLabel:Label;
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
		_countLabel = new Label( "", $widthParam );
		_countLabel.fontColor = 0xffffff;
        _countLabel.fontSize = 14;
		_countLabel.textAlign = TextAlign.CENTER;
		//_countLabel.x = 16;
		_countLabel.y = 3;

		_nameLabel = new Label( "", $widthParam );
		_nameLabel.fontColor = 0xffffff;
        _nameLabel.fontSize = _nameLabel.fontSize + 1;
		_nameLabel.textAlign = TextAlign.CENTER;
		//_countLabel.x = 16;
		_nameLabel.y = 105;
		addElement(_countLabel);
		addElement(_nameLabel);
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
	
	public function updateModelInfo( $mi:ModelInfo, $displayAddons:Boolean = true ):void {
        if ( $mi ) {
            if ( $mi.thumbnailLoaded && $mi.thumbnail )
                backgroundTexture = drawScaled( $mi.thumbnail, width, height );
            else
                ModelInfoEvent.addListener( ModelInfoEvent.BITMAP_LOADED, thumbnailLoaded );

            // listen for changes to this object
            ModelInfoEvent.addListener( ModelBaseEvent.UPDATE, metadataChanged );

            _nameLabel.text = $mi.name;
            var permissions:PermissionsModel = $mi.permissions;
            var modelsOfThisGuid:int = permissions.copyCount;
            if ( 99999 < modelsOfThisGuid )
                _countLabel.text = "lots";
            else if ( -1 == modelsOfThisGuid )
                _countLabel.text = "∞";
            else
                _countLabel.text = String( modelsOfThisGuid );

            setHelp( "guid: " + $mi.guid );

            var role:Role = Player.player.role;
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
        function editModelData( $me:UIMouseEvent ):void {
            var t:ObjectModel = _objectInfo as ObjectModel;
            var modelInfo:ModelInfo = t.modelInfo;
            if ( modelInfo && !PopupModelInfo.inExistance )
                new PopupModelInfo( modelInfo );
        }
	}
	protected var _type:int; // Used when it is a voxel
	public function get count():String { return _countLabel.text; }
	public function updateObjectInfo( $item:ObjectInfo, $displayAddons:Boolean = true ):void {
        // this may or may not have this event registered, but we need to make sure its not in more than one.
		ModelInfoEvent.removeListener( ModelBaseEvent.UPDATE, metadataChanged );
        InventoryVoxelEvent.removeListener(InventoryVoxelEvent.COUNT_RESULT, receiveVoxelCount);
		if ( null == $item )
			return;
			
		_objectInfo = $item;
		data = $item;
		_nameLabel.text = "";
        _type = 0;

        switch ( $item.objectType ) {
			case ObjectInfo.OBJECTINFO_EMPTY:
				reset();
				backgroundTexture = $item.backgroundTexture(width);
				break;
			case ObjectInfo.OBJECTINFO_MODEL:
				var om:ObjectModel = _objectInfo as ObjectModel;
				updateModelInfo( om.modelInfo, $displayAddons );
				break;

			case ObjectInfo.OBJECTINFO_ACTION:
				var oa:ObjectAction = $item as ObjectAction;
				backgroundTexture = $item.backgroundTexture( width );
				setHelp( oa.name );
				_countLabel.text = "";
				break;

			case ObjectInfo.OBJECTINFO_TOOL:
				var ot:ObjectTool = $item as ObjectTool;
				backgroundTexture = $item.backgroundTexture( width );
				setHelp( ot.name );
				_countLabel.text = "";
				if ( _editData ) {
					removeElement(_editData);
					_editData = null;
				}

				_nameLabel.text = "";
				break;

			case ObjectInfo.OBJECTINFO_VOXEL:
			default:
				updateVoxelInfo( $item as ObjectVoxel );
				break;
        }
	}

	private function updateVoxelInfo( ov:ObjectVoxel ):void {
       _type = ov.type;

        var typeInfo:TypeInfo = TypeInfo.typeInfo[_type];
        if ( typeInfo ) {
            backgroundTexture = ov.backgroundTexture( width );
            setHelp( typeInfo.name );
        }
        else {
            throw new Error( "BoxInventory.updateObjectInfo typeInfo not found for typeId: " + _type, Log.ERROR );
        }

        _countLabel.fontColor = typeInfo.countColor;
        formatOxelCountLabel( ov.count );

        InventoryVoxelEvent.addListener(InventoryVoxelEvent.COUNT_RESULT, receiveVoxelCount);
	}

    private function receiveVoxelCount( $ie:InventoryVoxelEvent):void {
        if ( _type == $ie.typeId ) {
            var count:int = ($ie.result as int);
            formatOxelCountLabel( count );
        }
    }

	private static const PerSquareMeter:int = 4096;
	private function formatOxelCountLabel( $count:int ):void {
        var count:Number = $count / PerSquareMeter;
		if ( 10 < count )
        	_countLabel.text = count.toFixed(0);
		else if ( 1 < count )
            _countLabel.text = count.toFixed(2);
		else
            _countLabel.text = count.toFixed(4);
	}

	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
        reset();
		// while it is active we want to monitor the count of oxels as they change
	}
	
	public function reset():void {
		setHelp( "Empty" );
		_countLabel.text = "";
		backgroundTexture = TextureBank.BLANK_IMAGE;
		data = null;
		if ( _editData ) {
			removeElement( _editData );
			_editData = null
		}

		_objectInfo = new ObjectInfo( this, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME );
	}
}
}