/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {
import com.voxelengine.worldmodel.inventory.Voxels;

import flash.display.DisplayObject;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.GUI.crafting.*;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.actionBars.QuickInventory;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.SecureInt;
import com.voxelengine.worldmodel.inventory.ObjectVoxel;

public class InventoryPanelVoxel extends VVContainer
{
	static private const VOXEL_CONTAINER_WIDTH:int = 512;
	static private const VOXEL_IMAGE_WIDTH:int = 64;
	static private const VOXEL_IMAGE_HEIGHT:int = 64;

	private var _dragOp:DnDOperation = new DnDOperation();
	private var _barUpper:TabBar;
	private var _barLower:TabBar;
	private var _itemContainer:Container = new Container( VOXEL_IMAGE_WIDTH, VOXEL_IMAGE_HEIGHT);
    private var _voxelData:Vector.<SecureInt>;
	
	public function InventoryPanelVoxel( $parent:VVContainer, $dataSource:String )
	{
		// TODO I notice when I repeatedly open and close this window that more and more memory is allocated
		super( $parent );
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		upperTabsAdd();

        addElement( _itemContainer );
        _itemContainer.autoSize = true;
        _itemContainer.layout.orientation = LayoutOrientation.VERTICAL;

		lowerTabsAdd();
        InventoryVoxelEvent.addListener( InventoryVoxelEvent.TYPES_RESULT, populateVoxels );
        displaySelectedSource( $dataSource );

		// This forces the window into a multiple of 64 width
		var count:int = width / 64;
		width = count * 64;

		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
	}
	
	private function upperTabsAdd():void {
		_barUpper = new TabBar();
		_barUpper.orientation = ButtonBarOrientation.VERTICAL;
		_barUpper.name = "upper";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_EARTH ), Voxels.VOXEL_CAT_EARTH );
		_barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_LIQUID ), Voxels.VOXEL_CAT_LIQUID );
		_barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_PLANT ), Voxels.VOXEL_CAT_PLANT );
		_barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_METAL ), Voxels.VOXEL_CAT_METAL );
		_barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_AIR ), Voxels.VOXEL_CAT_AIR );
		var li:ListItem = _barUpper.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_ALL ), Voxels.VOXEL_CAT_ALL );
		_barUpper.setButtonsWidth( 96, 32 );
		_barUpper.selectedIndex = li.index;
		eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barUpper );
	}

	private function lowerTabsAdd():void {
		_barLower = new TabBar();
		_barLower.orientation = ButtonBarOrientation.VERTICAL;
		_barLower.name = "lower";
		// TODO I should really iterate thru the types and collect the categories - RSF
		//_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_BEAST ), Voxels.VOXEL_CAT_BEAST );
		_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_UTIL ), Voxels.VOXEL_CAT_UTIL );
		_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_GEM ), Voxels.VOXEL_CAT_GEM );
		_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_AVATAR ), Voxels.VOXEL_CAT_AVATAR );
		_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_LIGHT ), Voxels.VOXEL_CAT_LIGHT );
		_barLower.addItem( LanguageManager.localizedStringGet( Voxels.VOXEL_CAT_CRAFTING ), Voxels.VOXEL_CAT_CRAFTING );
		_barLower.setButtonsWidth( 96, 32 );
		eventCollector.addEvent( _barLower, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barLower );
	}
	
	private function selectCategory(e:ListEvent):void {
		//Log.out( "PanelVoxelInventory.selectCategory" );
		while ( 1 <= _itemContainer.numElements )
			_itemContainer.removeElementAt( 0 );
		
		if ( e.target.name == "lower" )
			_barUpper.selectedIndex = -1;
		else
			_barLower.selectedIndex = -1;
			
		displaySelectedCategory( e.target.value );	
	}

    private function displaySelectedSource( $source:String ):void {
        if ( $source == WindowInventoryNew.SOURCE_PUBLIC )
            InventoryVoxelEvent.create( InventoryVoxelEvent.TYPES_REQUEST, Network.PUBLIC, -1, Voxels.VOXEL_CAT_ALL );
        else if ( $source == WindowInventoryNew.SOURCE_BACKPACK )
            InventoryVoxelEvent.create( InventoryVoxelEvent.TYPES_REQUEST, Network.userId, -1, Voxels.VOXEL_CAT_ALL );
        else
            InventoryVoxelEvent.create( InventoryVoxelEvent.TYPES_REQUEST, Network.storeId, -1, Voxels.VOXEL_CAT_ALL );
    }

	private function displaySelectedCategory( $category:String ):void {
        while (1 <= _itemContainer.numElements)
            _itemContainer.removeElementAt(0);
        var count:int = 0;
        var pc:Container = new Container( VOXEL_CONTAINER_WIDTH, VOXEL_IMAGE_HEIGHT );
        pc.layout = new AbsoluteLayout();

        var countMax:int = VOXEL_CONTAINER_WIDTH / VOXEL_IMAGE_HEIGHT;
        var box:BoxInventory;
        var item:TypeInfo;

        for (var typeId:int=0; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
        {
            item = TypeInfo.typeInfo[typeId];
            if ( 152 == typeId)
                Log.out( "Voxels.populateVoxel type ID is VINE");
            if ( null == item )
                continue;
            var voxelCount:int = _voxelData[typeId].val;
            if ( voxelCount <= 0 )
                voxelCount = 1000000;

			var ti:TypeInfo = TypeInfo.typeInfo[typeId];
			if ( ti ) {
				var catData:String = ti.category;
				if ( $category.toUpperCase() == catData.toUpperCase() || $category == Voxels.VOXEL_CAT_ALL ) {
					if ( item.placeable && -1 < voxelCount ) {
						// Add the filled bar to the container and create a new container
						if ( countMax == count ) {
							_itemContainer.addElement( pc );
							pc = new Container( VOXEL_CONTAINER_WIDTH, VOXEL_IMAGE_HEIGHT );
							pc.layout = new AbsoluteLayout();
							count = 0;
						}
						box = new BoxInventory(VOXEL_IMAGE_WIDTH, VOXEL_IMAGE_HEIGHT, BorderStyle.NONE );
						box.updateObjectInfo( new ObjectVoxel( box, typeId ) );
						box.x = count * VOXEL_IMAGE_WIDTH;
						pc.addElement( box );
						eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

						count++
					}
				}
			}
        }
        _itemContainer.addElement( pc );
	}
	
	private function populateVoxels( e:InventoryVoxelEvent ):void {

        _voxelData = e.result as Vector.<SecureInt>;
        InventoryVoxelEvent.removeListener(InventoryVoxelEvent.TYPES_RESULT, populateVoxels);
        displaySelectedCategory(Voxels.VOXEL_CAT_ALL);
    }


	private function dropMaterial(e:DnDEvent):void 	{
		if ( e.dragOperation.initiator.data is ObjectVoxel )
		{
			e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
			e.dropTarget.data = e.dragOperation.initiator.data;
			
			if ( e.dropTarget.target is PanelMaterials ) {
				CraftingItemEvent.create( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo );
			}
			else if ( e.dropTarget.target is PanelBonuses ) {
				CraftingItemEvent.create( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo );
				e.dropTarget.backgroundTextureManager.resize( 32, 32 );
			}
			else if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectVoxel = e.dragOperation.initiator.data as ObjectVoxel;
					bi.updateObjectInfo( item ); // 
					var slotId:int = int( bi.name );
					InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, slotId, item );
				}
			}
		}
	}
	
	private function doDrag(e:UIMouseEvent):void {
		_dragOp.initiator = e.target as UIObject;
		_dragOp.dragImage = e.target as DisplayObject;
		// this adds a drop format, which is checked again what the target is expecting
		_dragOp.resetDropFormat();
		var typeId:int = e.target.data.type;
		var ti:TypeInfo = TypeInfo.typeInfo[typeId];
		var dndFmt:DnDFormat = new DnDFormat( ti.category, ti.subCat );
		_dragOp.addDropFormat( dndFmt );
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
}
}