/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {
import flash.display.DisplayObject;
import flash.events.MouseEvent;
import org.flashapi.swing.containers.UIContainer;

//import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.GUI.crafting.*;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.SecureInt;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.inventory.ObjectVoxel;

public class InventoryPanelVoxel extends VVContainer
{
	static private const VOXEL_CAT_ALL:String 		= "All";
	static private const VOXEL_CAT_EARTH:String 	= "Earth";
	static private const VOXEL_CAT_LIQUID:String 	= "Liquid";
	static private const VOXEL_CAT_PLANT:String 	= "Plant";
	static private const VOXEL_CAT_METAL:String 	= "Metal";
	static private const VOXEL_CAT_AIR:String 		= "Air";
	static private const VOXEL_CAT_BEAST:String 	= "Beast";
	static private const VOXEL_CAT_UTIL:String 		= "Util";
	static private const VOXEL_CAT_GEM:String 		= "Gem";
	static private const VOXEL_CAT_AVATAR:String 	= "Avatar";
	static private const VOXEL_CAT_LIGHT:String 	= "Light";
	static private const VOXEL_CAT_CRAFTING:String 	= "Crafting";

	static private const VOXEL_CONTAINER_WIDTH:int = 512;
	static private const VOXEL_IMAGE_WIDTH:int = 64;
	
	private var _dragOp:DnDOperation = new DnDOperation();
	private var _barUpper:TabBar;
	private var _barLower:TabBar;
	private var _itemContainer:Container = new Container( VOXEL_IMAGE_WIDTH, VOXEL_IMAGE_WIDTH);
	
	public function InventoryPanelVoxel( $parent:VVContainer )
	{
		// TODO I notice when I repeatatly open and close this window that more and more memory is allocated
		// so something is not be released, or maybe I jsut need to be most patient for GC.
		super( $parent );
//			autoSize = true;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		upperTabsAdd();
		addItemContainer();
		lowerTabsAdd();
		displaySelectedCategory( "all" );
		
		// This forces the window into a multiple of 64 width
		var count:int = width / 64;
		width = count * 64;
		
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private function inventoryTestListeners():void { 
		
		InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, testInventoryVoxelResult ) ;
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST, Network.userId, TypeInfo.STONE, -1 ) );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST, Network.userId, TypeInfo.IRON, -1 ) );
		
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, Network.userId, TypeInfo.STONE, 1 ) );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, Network.userId, TypeInfo.STONE, 100 ) );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, Network.userId, TypeInfo.STONE, 1000 ) );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_CHANGE, Network.userId, TypeInfo.STONE, 10000 ) );
	}

	private function testInventoryVoxelResult(e:InventoryVoxelEvent):void 
	{
		Log.out( "WindowRegionModels.testInventoryVoxelResult - id: " + e.type + "  count: " + e.result );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	

	
	private function upperTabsAdd():void {
		_barUpper = new TabBar();
		_barUpper.orientation = ButtonBarOrientation.VERTICAL;
		_barUpper.name = "upper";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_EARTH ), VOXEL_CAT_EARTH );
		_barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_LIQUID ), VOXEL_CAT_LIQUID );
		_barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_PLANT ), VOXEL_CAT_PLANT );
		_barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_METAL ), VOXEL_CAT_METAL );
		_barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_AIR ), VOXEL_CAT_AIR );
		var li:ListItem = _barUpper.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_ALL ), VOXEL_CAT_ALL );
		_barUpper.setButtonsWidth( 96, 32 );
		_barUpper.selectedIndex = li.index;
		eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barUpper );
	}

	private function addItemContainer():void {
		addElement( _itemContainer );
		_itemContainer.autoSize = true;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
	}
	private function lowerTabsAdd():void {
		_barLower = new TabBar();
		_barLower.orientation = ButtonBarOrientation.VERTICAL;
		_barLower.name = "lower";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_BEAST ), VOXEL_CAT_BEAST );
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_UTIL ), VOXEL_CAT_UTIL );
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_GEM ), VOXEL_CAT_GEM );
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_AVATAR ), VOXEL_CAT_AVATAR );
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_LIGHT ), VOXEL_CAT_LIGHT );
		_barLower.addItem( LanguageManager.localizedStringGet( VOXEL_CAT_CRAFTING ), VOXEL_CAT_CRAFTING );
		_barLower.setButtonsWidth( 96, 32 );
		eventCollector.addEvent( _barLower, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barLower );
	}
	
	private function selectCategory(e:ListEvent):void 
	{			
		//Log.out( "PanelVoxelInventory.selectCategory" );
		while ( 1 <= _itemContainer.numElements )
			_itemContainer.removeElementAt( 0 );
		
		if ( e.target.name == "lower" )
			_barUpper.selectedIndex = -1;
		else
			_barLower.selectedIndex = -1;
			
		displaySelectedCategory( e.target.value );	
	}
	
	private function displaySelectedCategory( $category:String ):void {
		InventoryManager.addListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, populateVoxels );
		InventoryManager.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_REQUEST, Network.userId, -1, $category ) );
	}
	
	private function populateVoxels(e:InventoryVoxelEvent):void {
		
		var results:Vector.<SecureInt> = e.result as Vector.<SecureInt>;
		InventoryManager.removeListener( InventoryVoxelEvent.INVENTORY_VOXEL_TYPES_RESULT, populateVoxels );
		
		var count:int = 0;
		var pc:Container = new Container( VOXEL_CONTAINER_WIDTH, VOXEL_IMAGE_WIDTH );
		pc.layout = new AbsoluteLayout();

		var countMax:int = VOXEL_CONTAINER_WIDTH / VOXEL_IMAGE_WIDTH;
		var box:BoxInventory;
		var item:TypeInfo;
		
		for (var typeId:int; typeId < TypeInfo.MAX_TYPE_INFO; typeId++ )
		{
			item = TypeInfo.typeInfo[typeId];
			if ( null == item )
				continue;
			var voxelCount:int = results[typeId].val;
			if ( item.placeable && 0 < voxelCount)
			{
				// Add the filled bar to the container and create a new container
				if ( countMax == count )
				{
					_itemContainer.addElement( pc );
					pc = new Container( VOXEL_CONTAINER_WIDTH, VOXEL_IMAGE_WIDTH );
					pc.layout = new AbsoluteLayout();
					count = 0;		
				}
				box = new BoxInventory(VOXEL_IMAGE_WIDTH, VOXEL_IMAGE_WIDTH, BorderStyle.NONE, item );
				box.x = count * VOXEL_IMAGE_WIDTH;
				pc.addElement( box );
				eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

				count++
			}
		}
		_itemContainer.addElement( pc );
		
	}
	
	private function dropMaterial(e:DnDEvent):void 
	{
		if ( e.dragOperation.initiator.data is TypeInfo )
		{
			e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
			e.dropTarget.data = e.dragOperation.initiator.data;
			
			if ( e.dropTarget.target is PanelMaterials ) {
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
			}
			else if ( e.dropTarget.target is PanelBonuses ) {
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				e.dropTarget.backgroundTextureManager.resize( 32, 32 );
			}
			else if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectInfo;
					if ( e.dragOperation.initiator.data is TypeInfo )
						item = new ObjectVoxel( e.dragOperation.initiator.data.type );
					else
						Log.out( "InventoryPanelVoxel.dropMaterial - unknow type: " + (e.dragOperation.initiator.data).toString(), Log.ERROR );
					bi.updateObjectInfo( item );
					var slotId:int = int( bi.name );
					InventoryManager.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, slotId, item ) );
				}
			}
		}
	}
	
	private function doDrag(e:UIMouseEvent):void 
	{
		_dragOp.initiator = e.target as UIObject;
		_dragOp.dragImage = e.target as DisplayObject;
		// this adds a drop format, which is checked again what the target is expecting
		_dragOp.resetDropFormat();
		var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
		_dragOp.addDropFormat( dndFmt );
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
	
}
}