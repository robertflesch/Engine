/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.GUI.WindowModelDeleteChildrenQuery;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.ModelCache;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.types.VoxelModel;
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
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;
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
	private var _infoContainer:Container;
	private var _currentRow:Container;
	private var _seriesModelMetadataEvent:int;
	
	public function InventoryPanelModel( $parent:VVContainer ) {
		super( $parent );
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		FunctionRegistry.functionAdd( createNewObjectIPM, "createNewObjectIPM" );
		FunctionRegistry.functionAdd( importObjectIPM, "importObjectIPM" );
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, addModelMetadataEvent );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, addModelMetadataEvent );
		
		upperTabsAdd();
		addItemContainer();
		addTrashCan();
		addTools();
		displaySelectedCategory( "all" );
		
		// This forces the window into a multiple of MODEL_IMAGE_WIDTH width
		var count:int = width / MODEL_IMAGE_WIDTH;
		width = count * MODEL_IMAGE_WIDTH;
		
		eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOUSE_DOWN, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOUSE_MOVE, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_ENTER, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOVE_OVER, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_EXIT, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_COMPLETE, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_FINISH, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_START, dndTest );
		//function dndTest(e:DnDEvent):void 
		//{
			//Log.out( "InventoryPanelModel.dndTest msg: " + e );
		//}		
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
	
	private function addTrashCan():void {
		_infoContainer = new Container();
		_infoContainer.autoSize = true;
		addElement( _infoContainer );
		var b:BoxTrashCan = new BoxTrashCan(100, 100, BorderStyle.RIDGE );
		b.backgroundTexture = "assets/textures/trashCan.png";
		b.dropEnabled = true;
		_infoContainer.addElement( b );
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
		//Log.out( "InventoryPanelModels.displaySelectedCategory - Not implemented", Log.WARN );
		var mme:ModelMetadataEvent = new ModelMetadataEvent( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId, null )
		// The series makes it so that I dont see results from other objects requests
		_seriesModelMetadataEvent = mme.series;
		ModelMetadataEvent.dispatch( mme );
	}

	private function addModelMetadataEvent($mme:ModelMetadataEvent):void {
		
		// I only want the results from the series I asked for
		if ( _seriesModelMetadataEvent == $mme.series || 0 == $mme.series ) {
			var om:ObjectModel = new ObjectModel( null, $mme.modelGuid );
			om.vmm = $mme.modelMetadata;
			addModel( om );
		}
	}
	
	private function addModel( $oi:ObjectInfo, allowDrag:Boolean = true ):BoxInventory {
		//// Add the filled bar to the container and create a new container
		
		if ( ObjectInfo.OBJECTINFO_MODEL == $oi.objectType ) {
			var om:ObjectModel = $oi as ObjectModel;
			// dont show child models
			if ( !WindowInventoryNew._s_hackShowChildren )
				if ( null != om.vmm.animationClass && "" != om.vmm.animationClass )
					return null;
		}
				
		var box:BoxInventory = findFirstEmpty();	
		if ( box ) {
			box.updateObjectInfo( $oi );
			if ( allowDrag )
				eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
			if ( WindowInventoryNew._s_hackSupportClick	)
				eventCollector.addEvent( box, UIMouseEvent.CLICK, addModelTo );

			return box;
		}
		Log.out( "InventoryPanelModel.addModel - Failed to addModel: " + $oi );
		return null
	}
	
	private function addModelTo( e:UIMouseEvent ):void {
		var om:ObjectModel = (e.target.objectInfo as ObjectModel);
		
		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = om.modelGuid;
		if ( VoxelModel.selectedModel )
			ii.controllingModel = VoxelModel.selectedModel;
		ModelMakerBase.load( ii );
		
		
		//if ( VoxelModel.selectedModel ) {
			//VoxelModel.selectedModel.childAdd( objectModel.clone() );
			//Log.out( "EditCursor.insertModel - adding as CHILD", Log.WARN );
		//}
		//else {  
			//Region.currentRegion.modelCache.add( objectModel.clone() );
			//Log.out( "EditCursor.insertModel - adding as PARENT", Log.WARN );
		//}
	}
	
	private function addEmptyRow( $countMax:int ):void {
		_currentRow = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_WIDTH );
		_currentRow.layout = new AbsoluteLayout();
		_itemContainer.addElement( _currentRow );
		_itemContainer.height = _itemContainer.numElements * MODEL_IMAGE_WIDTH;
		for ( var i:int; i < $countMax; i++ ) {
			var box:BoxInventory = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_WIDTH, BorderStyle.NONE );
			box.updateObjectInfo( new ObjectInfo( box, ObjectInfo.OBJECTINFO_EMPTY ) );
			box.x = i * MODEL_IMAGE_WIDTH;
			_currentRow.addElement( box );
		}
	}
	
	private function findFirstEmpty():BoxInventory {
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		if ( null == _currentRow )
			addEmptyRow( countMax );
		for ( var i:int; i < countMax; i++ ) {
			var bie:* = _currentRow.getElementAt( i );
			var bi:* = bie.getElement();
			var box:BoxInventory = bi as BoxInventory;
			var oi:ObjectInfo = box.objectInfo;
			if ( ObjectInfo.OBJECTINFO_EMPTY == oi.objectType )
				return box;
		}
		addEmptyRow( countMax );
		return findFirstEmpty();
	}
	
	private function addTools():void {

		var box:BoxInventory;
		
		box = addModel( new ObjectAction( box, "createNewObjectIPM", "NewModel128.png", "Click to create new model" ), false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		
		if ( Globals.g_debug ) {
			box = addModel( new ObjectAction( box, "importObjectIPM", "import128.png", "Click to import local model" ), false );
			eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		}
	}
	
	static private function createNewObjectIPM():void {
		new WindowModelChoice();
	}
	
	static private function importObjectIPM():void {
		addDesktopModelHandler( null );
	}
	
	static private function addDesktopModelHandler(event:UIMouseEvent):void {
		var fr:FileReference = new FileReference();
		fr.addEventListener(Event.SELECT, onDesktopModelFileSelected );
		var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.mjson");
		fr.browse([swfTypeFilter]);
	}
	
	static public function onDesktopModelFileSelected(e:Event):void {
		Log.out( "onDesktopModelFileSelected : " + e.toString() );
		
		//if ( selectedModel
		var fileName:String = e.currentTarget.name;
		fileName = fileName.substr( 0, fileName.indexOf( "." ) );

		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = fileName;
		ModelMakerBase.load( ii );
	}
	
	private function removeModel( $modelGuid:String ):void {
		
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		var column:int = 0
		var rows:int = _itemContainer.numElements;
		for ( var row:int; row < rows; row++ ) {
			var rowElement:Element = _itemContainer.getElementAt( row );
			var rowCont:* = rowElement.getElement();
			for ( column = 0; column < countMax; column++ ) {
				var bie:* = rowCont.getElementAt( column );
				var bi:* = bie.getElement();
				var box:BoxInventory = bi as BoxInventory;
				var oi:ObjectInfo = box.objectInfo;
				if ( oi.objectType != ObjectInfo.OBJECTINFO_MODEL )
					continue;
				var om:ObjectModel = bi.objectInfo as ObjectModel;
				if ( om.modelGuid == $modelGuid ) {
					var newOI:ObjectInfo = new ObjectInfo(null, ObjectInfo.OBJECTINFO_EMPTY)
					box.updateObjectInfo( newOI );
					Log.out( "InventoryPanelModels.removeModel found model: " + $modelGuid );
					return;
				}
			}
		}
		Log.out( "InventoryPanelModels.removeModel DID NOT NOT find model: " + $modelGuid, Log.WARN );
	}
	
	private function dropMaterial(e:DnDEvent):void  {
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
			if ( e.dropTarget is BoxTrashCan ) {
				var btc:BoxTrashCan = e.dropTarget as BoxTrashCan;
				var droppedItem:ObjectModel = e.dragOperation.initiator.data;
				
				new WindowModelDeleteChildrenQuery( droppedItem.modelGuid, removeModel );				
			}
			
			if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectModel = e.dragOperation.initiator.data;
					bi.updateObjectInfo( item );
					var slotId:int = int( bi.name );
					InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, Network.userId, slotId, item ) );
					// we are going to need the data to build the model for this.
					OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST, 0, item.modelGuid, null ) );
				}
			}
		}
	}
	
	private function doDrag(e:UIMouseEvent):void {
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