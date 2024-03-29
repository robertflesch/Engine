/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.events.VVMouseEvent;
import com.voxelengine.worldmodel.TextureBank;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.models.ModelPlacementType;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;

import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.UIManager;
import org.flashapi.swing.event.DnDEvent;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.core.UIObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.InventoryInterfaceEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.RoomEvent;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.types.EditCursor;

public class  UserInventory extends QuickInventory
{
	static private var _s_currentInstance:UserInventory;
	
	private var _dragOp:DnDOperation = new DnDOperation();
	private var _toolSize:GrainSelector;
	private var _shape:ShapeSelector;
	private var _modelTools:ModelPlacementType;
	private var _inventory:InventoryIcon;
	private var _propList:PropListIcon;
	private var _lastCursorType:int;
		
	private var _remove:Boolean;
	private var _owner:String;
	private var _inventoryLoaded:Boolean;

	private var 		 _itemMaterialSelection:int = -1;
	private function get itemMaterialSelection():int  { return _itemMaterialSelection; }
	private function set itemMaterialSelection(value:int):void {
		//Log.out( "UserInventory.itemMaterialSelection: " + value )
		_itemMaterialSelection = value; 
	}
	
	private var 		 _lastBoxesSelection:int = -1;
	private function get lastBoxesSelection():int  { return _lastBoxesSelection; }
	private function set lastBoxesSelection(value:int):void {
		//Log.out( "UserInventory.lastItemSelection: " + value )
		_lastBoxesSelection = value; 
	}

	static public function init():void {	
		InventoryInterfaceEvent.addListener( InventoryInterfaceEvent.CLOSE, closeEvent );
		InventoryInterfaceEvent.addListener( InventoryInterfaceEvent.DISPLAY, displayEvent );
	}
	
	public function UserInventory( $owner:String, $image:String ) {
		_owner = $owner;
		//Log.out( "UserInventory.create ===================== <<<<<<<<< " + _owner + " <<<<<<<<<<<< ========================", Log.WARN );
		super( 680, 84, 64, $image );
		_selectorXOffset = 20; // From image of "userInventory.png"
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_CANCELED, dropInAir );
		buildItems();
		_toolSize = new GrainSelector();
		addChild(_toolSize);
		
		_shape = new ShapeSelector();
		addChild(_shape);
		
		_modelTools = new ModelPlacementType();
		addChild(_modelTools);
		
		_inventory = new InventoryIcon( width );
		addChild( _inventory );

		_propList = new PropListIcon( width );
		addChild( _propList );
		
		hideGrainTools();
		hideModelTools();
		_inventory.visible = false;
		_propList.visible = false;
		
		_s_currentInstance = this;
		
		RoomEvent.addListener( RoomEvent.ROOM_JOIN_SUCCESS, onJoinRoomEvent );
		InventoryEvent.addListener( InventoryEvent.RESPONSE, inventoryLoaded );
		InventoryModelEvent.addListener( ModelBaseEvent.DELETE, modelDeleted );
		CursorOperationEvent.addListener( CursorOperationEvent.NONE, onCursorOperationNone )	
	}
	
	private function modelDeleted(e:InventoryModelEvent):void {
		for each ( var bi:BoxInventory in boxes ) {
			if ( bi.objectInfo is ObjectModel ) {
				var om:ObjectModel = bi.objectInfo as ObjectModel;
				if ( e.itemGuid == om.modelGuid )
					InventorySlotEvent.create( InventorySlotEvent.CHANGE, _owner, "", int(bi.name), null );
					if ( int(bi.name) == lastBoxesSelection ) {
						CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) );
						hideModelTools()
					}
					bi.reset()
			}
		}
	}
	
	private function onJoinRoomEvent(e:RoomEvent):void {
		displayEvent(null);
	}
	
	override public function remove():void {
		removeListeners();
		//Log.out( "UserInventory.remove ===================== <<<<<<<<<<< " + _owner + " <<<<<<<<<< ========================", Log.WARN );
		RoomEvent.removeListener( RoomEvent.ROOM_JOIN_SUCCESS, onJoinRoomEvent );
		InventoryEvent.removeListener( InventoryEvent.RESPONSE, inventoryLoaded );
		AppEvent.removeListener( Event.DEACTIVATE, onDeactivate );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.UNLOAD_REQUEST, _owner, null ) );
		CursorOperationEvent.removeListener( CursorOperationEvent.NONE, onCursorOperationNone )	;
		_toolSize.remove();
		_shape.remove();
		_inventory.remove();
		_propList.remove();
		_s_currentInstance = null;
		
		super.remove();
	}

	static private function displayEvent(e:InventoryInterfaceEvent):void {
		// build it the first time
		if ( null == _s_currentInstance && e )
			_s_currentInstance = new UserInventory( e.owner, e.image );
		// it exists, but belongs to a different controllable object
		// close it and open new one
		else if ( _s_currentInstance && e && _s_currentInstance._owner != e.owner ) {
			_s_currentInstance.remove();
			_s_currentInstance = new UserInventory( e.owner, e.image );
		}
		
		if ( Globals.inRoom && _s_currentInstance ) {
			_s_currentInstance.displayIt();
		}
	}

	private function displayIt():void {
		populate();
		visible = true;
		_inventory.visible = true;
		_propList.visible = true;
//				EditCursor.editing = true;
		addListeners();
		display();
		resizeObject( null );
		AppEvent.addListener( Event.DEACTIVATE, onDeactivate );
		processItemSelection( boxes[1], false );
	}
	
	static private function closeEvent(e:InventoryInterfaceEvent):void {
		if ( null == _s_currentInstance )
			return;
		_s_currentInstance.remove();
		//Log.out( "UserInventory.closeEvent ===================== <<<<<<<<<<< " + _owner + " <<<<<<<<<< ========================", Log.WARN );
	}

	private function populate():void {
		InventoryEvent.addListener( InventoryEvent.RESPONSE, inventoryLoaded );
		InventoryEvent.create( InventoryEvent.REQUEST, _owner, null );

	}
	private function inventoryLoaded(e:InventoryEvent):void {
		//Log.out( "UserInventory.inventoryLoaded - ENTER - owningModel: " + _owner + "  e.owningModel: " + e.owningModel, Log.WARN );
		if ( e.owner == _owner ) {
			InventoryEvent.removeListener( InventoryEvent.RESPONSE, inventoryLoaded );
			_inventoryLoaded = true;
			var inv:Inventory = e.result as Inventory;
			var slots:Slots = inv.slots;

			var items:Vector.<ObjectInfo> = slots.items;
			for ( var i:int = 0; i < Slots.ITEM_COUNT; i++ ) {
				var item:ObjectInfo = items[i];
				item.box = (boxes[i] as BoxInventory);
                item.box.updateObjectInfo( item, false );
			}
		}
//		else
//			Log.out( "UserInventory.inventoryLoaded - for non active guid: " + e.owningModel, Log.WARN );
	}
	
	/////////// start drag and drop //////////////////////////////////////////////////////
	private function dropInAir(e:DnDEvent):void  {
		if ( e.dragOperation.initiator is BoxInventory )
		{
			var bi:BoxInventory = e.dragOperation.initiator as BoxInventory;
			var slotId:int = int( bi.name );
			bi.reset();
			hideGrainTools();
			hideModelTools();
			
			InventorySlotEvent.create( InventorySlotEvent.CHANGE, _owner, "", slotId, null );
			// sets edit cursor to none
			CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) );
		}
	}
	
	
	
	private function dropMaterial(e:DnDEvent):void  {
		if ( e.dropTarget is BoxInventory && e.dragOperation.initiator is BoxInventory )
		{
			(e.dropTarget as BoxInventory).updateObjectInfo( e.dragOperation.initiator.data );
			(e.dragOperation.initiator as BoxInventory).reset();
		}
	}
	
	private function doDrag(e:UIMouseEvent):void  {
		_dragOp.initiator = e.target as UIObject;
		_dragOp.dragImage = e.target as DisplayObject;
		// this adds a drop format, which is checked again what the target is expecting
		if ( e.target.data is TypeInfo ) {
			if ( e.target.data.category ) {
				_dragOp.resetDropFormat();
				var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
				_dragOp.addDropFormat( dndFmt );
			}
			else
				Log.out( "UserInventory.doDrag - didnt find category for: " + e.target.data, Log.WARN );
		}
		else if ( e.target.data is ObjectInfo ) {		
			// What do I need to do with object info? for now, just prevent drag
			return;
		}
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
	/////////// end drag and drop //////////////////////////////////////////////////////
	
	private function buildItem( actionItem:ObjectInfo, count:int ):Object {
		var box:BoxInventory = new BoxInventory(_imageSize, _imageSize, BorderStyle.NONE );
		// actionItem
		eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

		_boxes[count] = box;
		var hk:Label = new Label("", 20);
		box.x = _imageSize * count + _selectorXOffset;
		box.y = height - _imageSize;
		box.name = String( count );
		if ( actionItem )
		{
			box.data = actionItem;
			if ( actionItem is ObjectVoxel )
				box.backgroundTexture = (actionItem as TypeInfo).image;
		}
		else
		{
			box.data = null;
			box.backgroundTexture = TextureBank.BLANK_IMAGE;
			box.dropEnabled = true;
		}
		addElement( box );
		
		hk.x = _imageSize * count + _selectorXOffset + _imageSize/2;
		hk.fontColor = 0xffffff;
		if ( count == 9 )
			hk.text = "0";
		else	
			hk.text = String( count + 1 );
			
		addElement(hk);
		
		eventCollector.addEvent( box, UIMouseEvent.PRESS, pressItem );
		eventCollector.addEvent( box, UIMouseEvent.RELEASE, releaseItem );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressItem );
		eventCollector.addEvent( hk, UIMouseEvent.RELEASE, releaseItem );
		
		return { box: box, hotkey:hk };
	}
	
	// Dont call this until 
	override protected function buildItems():void {
		name = "ItemSelector";
		
		var count:int = 0;
		// Should add what is in current inventory here.
		for  ( ; count < Slots.ITEM_COUNT;  )
		{
			buildItem( null, count++ );
		}
		
		addSelector();			
//		lastItemSelection = 0;
		
		width = Slots.ITEM_COUNT * 64;
	}

	private function pressItem(e:UIMouseEvent):void  {
		var box:UIObject = e.target as UIObject;
		//Log.out( "UserInventory.pressItem", Log.DEBUG );
		processItemSelection( box );
	}			
	
	private function releaseItem(e:UIMouseEvent):void {
	}			
	
	private function selectByIndex( $index:int ):void {
		//Log.out( "UserInventory.selectByIndex", Log.DEBUG );
		processItemSelection( boxes[$index] );
	}
	
	private function onDeactivate( $ae:Event ):void {
		//Log.out( "UserInventory - onDeactivate - DISABLE EDIT CURSOR DISABLED", Log.WARN );
		processItemSelection( boxes[1], false )
	}
	
	private function onCursorOperationNone(e:CursorOperationEvent):void { 
		hideModelTools();
		hideGrainTools();
		moveSelector( boxes[1] );
	}
	
	private function processItemSelection( box:UIObject, $propagate:Boolean = true ):void {
		//Log.out( "UserInventory.processItemSelection - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex + " box.name: " + box.name, Log.DEBUG );
		if ( 0 < Globals.openWindowCount )
			return;
			
		moveSelector( box );
		var boxesIndex:int = int( box.name ); // Boxes[0] uses hotkey 1
		
		//hideGrainTools();
		//;
		//EditCursor.editing = false;

		var oi:ObjectInfo = box.data as ObjectInfo;
		if ( oi is ObjectVoxel ) {
			var ti:ObjectVoxel = oi as ObjectVoxel;
			var selectedTypeId:int = ti.type;
			if ( TypeInfo.INVALID != selectedTypeId ) {
				itemMaterialSelection = boxesIndex;
				CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.INSERT_OXEL, selectedTypeId ) ); 
			}
			hideModelTools();
			showGrainTools();
		}
		else if ( oi is ObjectAction ) {
			//Log.out( "UserInventory.processItemSelection - ObjectAction - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex, Log.DEBUG );
			var oa:ObjectAction = oi as ObjectAction;
			if ( lastBoxesSelection == boxesIndex ) {
				// check for reload time of other blocking mechanism
				// oa.isBlocked
				//Log.out( "UserInventory.processItemSelection - ObjectAction - lastItemSelection == boxesIndex - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex, Log.DEBUG );
				if ( oa.ammoName && "null" != oa.ammoName )
					oa.callBack( oa.ammoName );
				else
					oa.callBack();
			} 
			else {
				//Log.out( "UserInventory.processItemSelection - ObjectAction - lastItemSelection != boxesIndex - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex, Log.DEBUG );
				if ( oa.ammoName && "null" != oa.ammoName )
					oa.callBack( oa.ammoName );
				else
					oa.callBack();
			}
		}
		else if ( oi is ObjectTool ) {
			//Log.out( "UserInventory.processItemSelection - ObjectTool");
			hideModelTools();
			var ot:ObjectTool = oi as ObjectTool;
			if ( lastBoxesSelection == boxesIndex ) {
				//Log.out( "UserInventory.processItemSelection - ObjectTool - lastItemSelection == boxesIndex - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex, Log.DEBUG );
				// we are double tapping the tool key
				if ( -1 != itemMaterialSelection ) {	
					var lastBoxPick:Box = boxes[itemMaterialSelection ];
					if ( $propagate ) {
						//Log.out( "UserInventory.processItemSelection.ObjectTool.- 1 != itemMaterialSelection", Log.WARN);
						processItemSelection( lastBoxPick )
					}
					return;
				}
				else {
					//Log.out( "UserInventory.processItemSelection - ObjectTool - lastItemSelection != boxesIndex - lastItemSelection: " + lastBoxesSelection + " boxesIndex: " + boxesIndex, Log.DEBUG );
					if ( $propagate ) {
						//Log.out( "UserInventory.processItemSelection.ObjectTool.other", Log.WARN);
						processItemSelection( boxes[1] )
					}
					return;
				}
			}
			else {
			   // We are selecting a new tool 
				ot.callBack();
				showGrainTools();
			}
		}
		else if ( oi is ObjectModel ) {
			Log.out( "UserInventory.processItemSelection - ObjectModel", Log.WARN);
			var ti1:TypeInfo = TypeInfo.typeInfo[ TypeInfo.NO_QUADS ];
			var om:ObjectModel = oi as ObjectModel;
			CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.INSERT_MODEL, ti1.type, om ) );
			
			hideGrainTools();
			showModelTools();
		}
		else if ( oi is ObjectInfo ) {
			//Log.out( "UserInventory.processItemSelection - ObjectInfo");
			CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) ); 
			hideGrainTools();
			hideModelTools();
		}
		
		lastBoxesSelection = boxesIndex;
	}
	
	private function onMouseWheel(event:MouseEvent):void {
		if ( event.ctrlKey || event.shiftKey || event.altKey )
			return;
			
		if ( 0 < event.delta ) {
			if ( lastBoxesSelection < (Slots.ITEM_COUNT - 1)  )
				selectByIndex( lastBoxesSelection + 1 );
			else if ( ( Slots.ITEM_COUNT -1 ) == lastBoxesSelection )
				selectByIndex( 0 );
		} else {
			if (0 == lastBoxesSelection)
				selectByIndex(Slots.ITEM_COUNT - 1);
			else if (0 < lastBoxesSelection)
				selectByIndex(lastBoxesSelection - 1);
		}
	}

	private function showGrainTools():void {
		_toolSize.show();
		_shape.show();
	}
	
	private function hideGrainTools():void {
		_toolSize.hide();
		_shape.hide();
	}

	private function showModelTools():void { _modelTools.show(); }
	private function hideModelTools():void { _modelTools.hide(); }

	private var _listenersAdded:Boolean;
	private function addListeners():void {
		Log.out( "UserInventory.addListeners ===================== <<<<<<<<<<< " + _owner + " <<<<<<<<<< ========================" );
		if ( false == _listenersAdded ) {
			VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
			VVMouseEvent.addListener( MouseEvent.MOUSE_WHEEL, onMouseWheel);
			_listenersAdded = true
		}
	}
	
	private function removeListeners():void {
		Log.out( "UserInventory.removeListeners ===================== <<<<<<<<<<< " + _owner + " <<<<<<<<<< ========================", Log.WARN );
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
		VVMouseEvent.addListener( MouseEvent.MOUSE_WHEEL, onMouseWheel);
		_listenersAdded = false;
	}

	private function hotKeyInventory(e:KeyboardEvent):void {
		//Log.out( "UserInventory.hotKeyInventory ", Log.WARN );
		if  ( !Globals.active )
			return;
			
		if ( 48 <= e.keyCode && e.keyCode <= 58 )
		{
			//Log.out( "UserInventory.hotKeyInventory - e.keyCode: " + e.keyCode );
			var selectedItem:int = e.keyCode - 48;
			if ( 0 < selectedItem )
				selectByIndex( selectedItem - 1 ); // 1 is index 0
			else	
				selectByIndex( 9 ); // index 9 is key 0
		}
		//else if ( 119 == e.keyCode )
		//{
			//_shape.pressShapeHotKey(e);
		//}
	}
}
}