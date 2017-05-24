/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

import com.voxelengine.GUI.PictureImportProperties;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

import flash.display.Bitmap;
import flash.display.BitmapData;

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.net.FileReference;
import flash.net.FileFilter;

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
import com.voxelengine.GUI.VVBox;
import com.voxelengine.GUI.actionBars.QuickInventory;
import com.voxelengine.GUI.crafting.BoxCharacterSlot;
import com.voxelengine.GUI.voxelModels.PopupMetadataAndModelInfo;
import com.voxelengine.GUI.WindowModelDeleteChildrenQuery;
import com.voxelengine.GUI.WindowPictureImport;

import com.voxelengine.events.CharacterSlotEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;

import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
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
	static private const MODEL_IMAGE_HEIGHT:int = 128;

	private var _dragOp:DnDOperation = new DnDOperation();
	private var _barLeft:TabBar;
	// This hold the items to be displayed
	// http://www.flashapi.org/spas-doc/org/flashapi/swing/ScrollPane.html
	private var _itemContainer:ScrollPane;
	private var _currentRow:Container;
	private var _seriesModelMetadataEvent:int;
	
	public function InventoryPanelModel( $parent:VVContainer ) {
		super( $parent );
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		FunctionRegistry.functionAdd( createNewObjectIPM, "createNewObjectIPM" );
		FunctionRegistry.functionAdd( importObjectIPM, "importObjectIPM" );
		FunctionRegistry.functionAdd( importObjectStainedGlass, "importObjectStainedGlass" );
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, addModelMetadataEvent );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, addModelMetadataEvent );
		ModelMetadataEvent.addListener( ModelBaseEvent.DELETE, removeModelMetadataEvent );
		// This was causing model to be added twice when importing.
		//ModelMetadataEvent.addListener( ModelBaseEvent.IMPORT_COMPLETE, addModelMetadataEvent );

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
		_itemContainer.height = MODEL_IMAGE_HEIGHT;
		_itemContainer.scrollPolicy = ScrollPolicy.VERTICAL;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		addElement( _itemContainer );
	}
	
	private function addTrashCan():void {
		var infoContainer:Container;
		infoContainer = new Container();
		infoContainer.autoSize = true;
		addElement( infoContainer );

		var b:BoxTrashCan = new BoxTrashCan(100, 100, BorderStyle.RIDGE );
		b.backgroundTexture = "assets/textures/trashCan.png";
		b.dropEnabled = true;
		infoContainer.addElement( b );
	}
	
	private function selectCategory(e:ListEvent):void {
		var test:String = e.target.value;
		while ( 1 <= _itemContainer.numElements )
			_itemContainer.removeElementAt( 0 );
		_barLeft.selectedIndex = -1;
			
		displaySelectedCategory( "All" );	
	}
	
	// TODO I see problem here when language is different then what is in TypeInfo RSF - 11.16.14
	// That is if I use the target "Name"
	private function displaySelectedCategory( $category:String ):void {
		//Log.out( "InventoryPanelModels.displaySelectedCategory - Not implemented", Log.WARN );
		// The series makes it so that I dont see results from other objects requests
		// This grabs the current series counter which will be used on the REQUEST_TYPE call
		_seriesModelMetadataEvent = ModelBaseEvent.seriesCounter;
		ModelMetadataEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId, null );
		ModelMetadataEvent.create( ModelBaseEvent.REQUEST_TYPE, _seriesModelMetadataEvent, Network.PUBLIC, null );
	}

	private function removeModelMetadataEvent($mme:ModelMetadataEvent):void {
		removeModel( $mme.modelGuid );
	}

	private function addModelMetadataEvent($mme:ModelMetadataEvent):void {
		// I only want the results from the series I asked for
		if ( _seriesModelMetadataEvent == $mme.series || 0 == $mme.series ) {
			if ( "Player" == $mme.modelGuid)
					return;
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
			//if ( !WindowInventoryNew._s_hackShowChildren )
			if ( VoxelModel.selectedModel ) {
				if ( null != om.vmm.childOf && "" != om.vmm.childOf ) {
					if ( VoxelModel.selectedModel.metadata.name != om.vmm.childOf ) {
						Log.out( "InventoryPanelModel.addModel - child model of wrong parent: " + om.vmm.name, Log.INFO );
						return null;
					}
				} else {
					Log.out("InventoryPanelModel.addModel - NOT child model of: " + om.vmm.name, Log.WARN);
					return null;
				}

			} else {
				if ( null != om.vmm.childOf && "" != om.vmm.childOf ) {
					Log.out( "InventoryPanelModel.addModel - NOT added child model of: " + om.vmm.name, Log.INFO );
					return null;
				}
			}
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
		Log.out( "InventoryPanelModel.addModel - Failed to addModel: " + $oi, Log.ERROR );
		return null
	}
	
	static private function addModelTo( e:UIMouseEvent ):void {
		if ( e.target.objectInfo is ObjectAction ) {
			var oa:ObjectAction = e.target.objectInfo as ObjectAction;
			var cb:Function = oa.callBack;
			// just execute the callback here, dont need to do cb(), which calls it twice, interesting
			cb;
		}
		else if ( e.target.objectInfo is ObjectModel ) {
			var om:ObjectModel = (e.target.objectInfo as ObjectModel);
			
			var ii:InstanceInfo = new InstanceInfo();
			ii.modelGuid = om.modelGuid;
			ii.instanceGuid = Globals.getUID();
			if ( VoxelModel.selectedModel )
				ii.controllingModel = VoxelModel.selectedModel;
			else {
				// Only do this for top level models.
				var size:int = Math.max( GrainCursor.get_the_g0_edge_for_grain(om.vmm.bound), 32 );
				// this give me edge,  really want center.
				var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.lookAtVector(size * 1.5);
				lav.setTo( lav.x - size/2, lav.y - size/2, lav.z - size/2);
				var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet().clone();
				diffPos = diffPos.add(lav);
				ii.positionSet = diffPos;
			}

			if ( !PopupMetadataAndModelInfo.inExistance )
				ModelMakerBase.load( ii );
		}
	}
	
	private function addEmptyRow( $countMax:int ):void {
		_currentRow = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_HEIGHT );
		_currentRow.layout = new AbsoluteLayout();
		_itemContainer.addElement( _currentRow );
		_itemContainer.height = _itemContainer.numElements * MODEL_IMAGE_WIDTH;
		for ( var i:int=0; i < $countMax; i++ ) {
			var box:BoxInventory = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_HEIGHT, BorderStyle.NONE );
			box.updateObjectInfo( new ObjectInfo( box, ObjectInfo.OBJECTINFO_EMPTY ) );
			box.x = i * MODEL_IMAGE_WIDTH;
			_currentRow.addElement( box );
		}
	}
	
	private function findFirstEmpty():BoxInventory {
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		if ( null == _currentRow )
			addEmptyRow( countMax );
		for ( var i:int=0; i < countMax; i++ ) {
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
		var box:BoxInventory = null;
		box = addModel( new ObjectAction( box, "createNewObjectIPM", "NewModel128.png", "Click to create new model" ), false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		
		box = addModel( new ObjectAction( box, "importObjectStainedGlass", "importPicture128.png", "Click to import picture" ), false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );

		if ( Globals.isDebug ) {
			box = addModel( new ObjectAction( box, "importObjectIPM", "import128.png", "Click to import local model" ), false );
			eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		}
	}
	
	static private function createNewObjectIPM():void {
		new WindowModelChoice();
		WindowInventoryNew._s_instance.remove()
	}
	
	static private function importObjectIPM():void {
		addDesktopModelHandler( null );
	}

	static private function importObjectStainedGlass():void {
		new WindowPictureImport();
	}

	static private function addDesktopModelHandler(event:UIMouseEvent):void {
		var fileRef:FileReference = new FileReference();
		fileRef.addEventListener(Event.SELECT, onDesktopModelFileSelected );
		fileRef.browse([new FileFilter("Model Files","*.mjson")]);
	}

	static public function onDesktopModelFileSelected(e:Event):void {
		Log.out( "onDesktopModelFileSelected : " + e.toString() );
		e.target.removeEventListener(Event.SELECT, onDesktopModelFileSelected );

		var fileName:String = e.currentTarget.name;
		fileName = fileName.substr( 0, fileName.indexOf( "." ) );

		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = fileName;
		new ModelMakerImport( ii );
	}




	private function removeModel( $modelGuid:String ):void {
		
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		var column:int = 0;
		var rows:int = _itemContainer.numElements;
		for ( var row:int=0; row < rows; row++ ) {
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
					var newOI:ObjectInfo = new ObjectInfo(null, ObjectInfo.OBJECTINFO_EMPTY);
					box.updateObjectInfo( newOI );
					//Log.out( "InventoryPanelModels.removeModel found model: " + $modelGuid );
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
				//var btc:BoxTrashCan = e.dropTarget as BoxTrashCan;
				var droppedItem:ObjectModel = e.dragOperation.initiator.data;

				new WindowModelDeleteChildrenQuery( droppedItem.modelGuid, removeModel );
			}

			if ( e.dropTarget is BoxCharacterSlot ) {
				var bcs:BoxCharacterSlot = e.dropTarget as BoxCharacterSlot;
				var om:ObjectModel = e.dragOperation.initiator.data;
				if ( om.vmm && om.vmm.thumbnailLoaded && om.vmm.thumbnail)
					bcs.backgroundTexture = VVBox.drawScaled(om.vmm.thumbnail, bcs.width, bcs.height);

				CharacterSlotEvent.create( CharacterSlotEvent.CHANGE, Network.userId, bcs.data, om.modelGuid );
				Log.out( "InventoryPanelModel.dropMaterial - slot: " + bcs.data + "  guid: " + om.modelGuid, Log.WARN );
			}

			
			if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectModel = e.dragOperation.initiator.data;
					bi.updateObjectInfo( item, false );
					var slotId:int = int( bi.name );
					InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, slotId, item );
					// we are going to need the oxelPersistence to build the model for this.
                    Log.out( "InventoryPanelModel.dropMaterial - ", Log.DEBUG );
					OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, item.modelGuid, null );
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
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, addModelMetadataEvent );
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, addModelMetadataEvent );
		ModelMetadataEvent.removeListener( ModelBaseEvent.DELETE, removeModelMetadataEvent );
		//ModelMetadataEvent.removeListener( ModelBaseEvent.IMPORT_COMPLETE, addModelMetadataEvent );
	}
}
}