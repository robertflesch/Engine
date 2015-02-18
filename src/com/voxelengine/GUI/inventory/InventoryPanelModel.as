package com.voxelengine.GUI.inventory {

import com.voxelengine.GUI.actionBars.QuickInventory;
import flash.display.DisplayObject;
import flash.net.FileReference;
import flash.events.Event;
import flash.net.FileFilter;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.framework.flashdevelop.FlashConnect;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.GUI.*;
import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.inventory.FunctionRegistry;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.inventory.ObjectModel;

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
	private var _itemContainer:Container = new Container( MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH);
	
	public function InventoryPanelModel( $parent:VVContainer ) {
		super( $parent );
		
		FunctionRegistry.functionAdd( createNewObjectIPM, "createNewObjectIPM" );
		FunctionRegistry.functionAdd( importObjectIPM, "importObjectIPM" );
			
		autoSize = true;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		upperTabsAdd();
		addItemContainer();
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
		addElement( _itemContainer );
		_itemContainer.autoSize = true;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
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
		InventoryManager.addListener( InventoryModelEvent.INVENTORY_MODEL_LIST_RESULT, populateModels );
		InventoryManager.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_LIST_REQUEST, Network.userId, "", $category ) );
	}
	
	private function populateModels(e:InventoryModelEvent):void 
	{
		var results:Array = e.result as Array;
		InventoryManager.removeListener( InventoryModelEvent.INVENTORY_MODEL_LIST_RESULT, populateModels );
		
		var count:int = 0;
		var pc:Container = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_WIDTH );
		pc.layout = new AbsoluteLayout();

		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		var box:BoxInventory;
		var item:ObjectInfo;
		
		item = new ObjectAction( "createNewObjectIPM", "NewModel128.png", "Click to create new model" );
		box = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH, BorderStyle.NONE, item );
		box.x = count++ * MODEL_IMAGE_WIDTH;
		pc.addElement( box );
		
		if ( Globals.g_debug ) {
			item = new ObjectAction( "importObjectIPM", "import128.png", "Click to import local model" );
			box = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH, BorderStyle.NONE, item );
			box.x = count++ * MODEL_IMAGE_WIDTH;
			pc.addElement( box );
		}
		
		//eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		count++;

		for ( var key:String in results ) {	
			item = new ObjectModel( key );
			//item.image = "blank128.png";
			var itemCount:int = results[key].val;
			//// Add the filled bar to the container and create a new container
			if ( countMax == count )
			{
				_itemContainer.addElement( pc );
				pc = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_WIDTH );
				pc.layout = new AbsoluteLayout();
				count = 0;		
			}
			box = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH, BorderStyle.NONE, item );
			box.x = count * MODEL_IMAGE_WIDTH;
			pc.addElement( box );
			eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

			count++
		}
		_itemContainer.addElement( pc );
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

		new WindowModelMetadata( fileName );
	//	remove();
	}
	
	
	private function dropMaterial(e:DnDEvent):void 
	{
		if ( e.dragOperation.initiator.data is ObjectModel )
		{
			//e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
			//e.dropTarget.data = e.dragOperation.initiator.data;
			//
			//if ( e.dropTarget.target is PanelMaterials ) {
				//Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
			//}
			//else if ( e.dropTarget.target is PanelBonuses ) {
				//Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				//e.dropTarget.backgroundTextureManager.resize( 32, 32 );
			//}
			//else if ( e.dropTarget.target is QuickInventory ) {
			if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectModel = e.dragOperation.initiator.data;
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
//		_dragOp.resetDropFormat();
//		var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
//		_dragOp.addDropFormat( dndFmt );
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
}
}