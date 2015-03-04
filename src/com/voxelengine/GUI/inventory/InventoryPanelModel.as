/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.ModelMaker;
import com.voxelengine.worldmodel.models.ModelMetadata;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.net.FileReference;
import flash.net.FileFilter;
import org.flashapi.swing.containers.MainContainer;

import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.VVContainer;
import com.voxelengine.GUI.WindowModelChoice;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMakerImport;
import com.voxelengine.worldmodel.inventory.FunctionRegistry;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.inventory.ObjectModel;
import com.voxelengine.GUI.actionBars.QuickInventory;

public class InventoryPanelModel extends VVContainer
{
	// TODO need a more central location for these
	static public const MODEL_CAT_ARCHITECTURE:String = "Architecture";
	static public const MODEL_CAT_CHARACTERS:String = "Characters";
	static public const MODEL_CAT_PLANTS:String = "Plants";
	static public const MODEL_CAT_FURNITURE:String = "Furniture";
	static public const MODEL_CAT_ALL:String = "ALL";
	
	static private const MODEL_CONTAINER_WIDTH:int = 512;
	static private const MODEL_IMAGE_WIDTH:int = 128;
	
	private var _dragOp:DnDOperation = new DnDOperation();
	private var _barLeft:TabBar
	// This hold the items to be displayed
	// http://www.flashapi.org/spas-doc/org/flashapi/swing/ScrollPane.html
	private var _itemContainer:ScrollPane;
	private var _currentRow:Container;
	
	public function InventoryPanelModel( $parent:VVContainer ) {
		super( $parent );
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		FunctionRegistry.functionAdd( createNewObjectIPM, "createNewObjectIPM" );
		FunctionRegistry.functionAdd( importObjectIPM, "importObjectIPM" );
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, addModelMetadataEvent );
		
		upperTabsAdd();
		addItemContainer();
		populateModels();
		displaySelectedCategory( "all" );
		
		// This forces the window into a multiple of MODEL_IMAGE_WIDTH width
		var count:int = width / MODEL_IMAGE_WIDTH;
		width = count * MODEL_IMAGE_WIDTH;
		
		eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
	}
	
	private function upperTabsAdd():void {
		_barLeft = new TabBar();
		_barLeft.orientation = ButtonBarOrientation.VERTICAL;
		_barLeft.name = "left";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ARCHITECTURE ), MODEL_CAT_ARCHITECTURE );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_CHARACTERS ), MODEL_CAT_CHARACTERS );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_PLANTS ), MODEL_CAT_PLANTS );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_FURNITURE ), MODEL_CAT_FURNITURE );
		var li:ListItem = _barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ALL ), MODEL_CAT_ALL );
		_barLeft.setButtonsWidth( 96, 32 );
		_barLeft.selectedIndex = li.index;
		eventCollector.addEvent( _barLeft, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barLeft );
	}

	private function addItemContainer():void {
		_itemContainer = new ScrollPane();
		_itemContainer.autoSize = false;
		_itemContainer.width = MODEL_CONTAINER_WIDTH + 15;
		_itemContainer.height = MODEL_IMAGE_WIDTH;
		_itemContainer.scrollPolicy = ScrollPolicy.VERTICAL;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		addElement( _itemContainer );
	}
	
	private function selectCategory(e:ListEvent):void 
	{			
		var test:String = e.target.value;
		while ( 1 <= _itemContainer.numElements )
			_itemContainer.removeElementAt( 0 );
		_barLeft.selectedIndex = -1;
			
		displaySelectedCategory( "All" );	
	}
	
	// TODO I see problem here when langauge is different then what is in TypeInfo RSF - 11.16.14
	// That is if I use the target "Name"
	private function displaySelectedCategory( $category:String ):void
	{	
		Log.out( "InventoryPanelModels.displaySelectedCategory - Not implemented", Log.WARN );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_TYPE, Network.userId, null ) );
	}

	private function addModelMetadataEvent($mme:ModelMetadataEvent):void {
		
		var om:ObjectModel = new ObjectModel( null, $mme.guid );
		om.vmm = $mme.vmm;
		addModel( om );
	}
	
	private function addModel( $oi:ObjectInfo, allowDrag:Boolean = true ):BoxInventory {
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		//// Add the filled bar to the container and create a new container
		if ( countMax == _currentRow.numElements )
		{
			_currentRow = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_WIDTH );
			_currentRow.layout = new AbsoluteLayout();
			_itemContainer.addElement( _currentRow );
			_itemContainer.height = _itemContainer.numElements * MODEL_IMAGE_WIDTH;
		}
		var box:BoxInventory = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH, BorderStyle.NONE );
		box.updateObjectInfo( $oi );
		box.x = _currentRow.numElements * MODEL_IMAGE_WIDTH;
		_currentRow.addElement( box );
		if ( allowDrag )
			eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
		if ( $oi is ObjectModel )
			eventCollector.addEvent( box, UIMouseEvent.CLICK, addAsParentModel );
		return box;
	}
	
	private function addAsParentModel( e:UIMouseEvent ):void {
		var item:ObjectModel = e.target.objectInfo as ObjectModel;
		var ii:InstanceInfo = new InstanceInfo();
		ii.guid = item.guid;
		new ModelMaker( ii );
	}
	
	private function populateModels():void 
	{
		var count:int = 0;
		_currentRow = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_WIDTH );
		_currentRow.layout = new AbsoluteLayout();
		_itemContainer.addElement( _currentRow );

		var item:ObjectInfo;
		var box:BoxInventory;
		
		item = new ObjectAction( box, "createNewObjectIPM", "NewModel128.png", "Click to create new model" );
		box = addModel( item, false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		
		if ( Globals.g_debug ) {
			item = new ObjectAction( box, "importObjectIPM", "import128.png", "Click to import local model" );
			box = addModel( item, false );
			eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		}

		item = new ObjectAction( box, "createNewObjectIPM", "NewModel128.png", "Click to create new model" );
		box = addModel( item, false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
	}
	
	static private function createNewObjectIPM():void {
		new WindowModelChoice();
	}
	
	static private function importObjectIPM():void {
		addDesktopModelHandler( null );
	}
	
	static private function addDesktopModelHandler(event:UIMouseEvent):void 
	{
		var fr:FileReference = new FileReference();
		fr.addEventListener(Event.SELECT, onDesktopModelFileSelected );
		var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.mjson");
		fr.browse([swfTypeFilter]);
	}
	
	static public function onDesktopModelFileSelected(e:Event):void
	{
		Log.out( "onDesktopModelFileSelected : " + e.toString() );
		
		//if ( selectedModel
		var fileName:String = e.currentTarget.name;
		fileName = fileName.substr( 0, fileName.indexOf( "." ) );

		var ii:InstanceInfo = new InstanceInfo();
		ii.guid = fileName;
		new ModelMakerImport( ii );
	}
	
	
	private function dropMaterial(e:DnDEvent):void 
	{
		if ( e.dragOperation.initiator.data is ObjectModel )
		{
			//e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
			//e.dropTarget.data = e.dragOperation.initiator.data;
			//
			//if ( e.dropTarget.target is PanelMaterials ) {
				//CraftingItemEvent.dispatch( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
			//}
			//else if ( e.dropTarget.target is PanelBonuses ) {
				//CraftingItemEvent.dispatch( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				//e.dropTarget.backgroundTextureManager.resize( 32, 32 );
			//}
			//else if ( e.dropTarget.target is QuickInventory ) {
			if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectModel = e.dragOperation.initiator.data;
					bi.updateObjectInfo( item );
					var slotId:int = int( bi.name );
					InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, slotId, item ) );
					// we are going to need the data to build the model for this.
					ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, item.guid, null ) );
				}
			}
		}
	}
	
	private function doDrag(e:UIMouseEvent):void 
	{
		_dragOp.initiator = e.target as UIObject;
		_dragOp.dragImage = e.target as DisplayObject;
		// this adds a drop format, which is checked again what the target is expecting
//		_dragOp.resetDropFormat();
//		var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
//		_dragOp.addDropFormat( dndFmt );
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
	
	override protected function onRemoved( event:UIOEvent ):void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, addModelMetadataEvent )
	}
}
}