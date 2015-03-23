/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
import flash.display.DisplayObject;
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
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.GUI.LoadingImage;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.types.EditCursor;

public class  UserInventory extends QuickInventory
{
	private var _dragOp:DnDOperation = new DnDOperation();
	private static var _itemMaterialSelection:int = -1;
	private static var _lastItemSelection:int = -1;
	private var _toolSize:GrainSelector;
	private var _shape:ShapeSelector;
	
	public function UserInventory() {
		super( 680, 84, 64, "userInventory.png" );
		_selectorXOffset = 20; // From image of "userInventory.png"
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_CANCELED, dropInAir );
		buildItems();
		_toolSize = new GrainSelector();
		addChild(_toolSize);
		
		_shape = new ShapeSelector();
		addChild(_shape);
		
		display();
		show();
		resizeObject( null );
		// this gets the already initialized inventory from the inventory manager
		InventoryEvent.addListener( InventoryEvent.INVENTORY_RESPONSE, inventoryLoaded );
		InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.INVENTORY_REQUEST, Network.userId, null ) );
	}

	private function inventoryLoaded(e:InventoryEvent):void {
		var inv:Inventory = e.result as Inventory;
		var slots:Slots = inv.slots;
		
		var items:Vector.<ObjectInfo> = slots.items;
		for ( var i:int; i < Slots.ITEM_COUNT; i++ ) {
			var item:ObjectInfo = items[i];
			item.box = (boxes[i] as BoxInventory);
			(boxes[i] as BoxInventory).updateObjectInfo( item );
		}
		
		resizeObject( null );
//		Globals.g_app.addEventListener( VVWindowEvent.WINDOW_CLOSING, shouldDisplay );			
	}
	
	/////////// start drag and drop //////////////////////////////////////////////////////
	private function dropInAir(e:DnDEvent):void  {
		if ( e.dragOperation.initiator is BoxInventory )
		{
			var bi:BoxInventory = e.dragOperation.initiator as BoxInventory;
			var slotId:int = int( bi.name );
			bi.reset();
			InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, slotId, null ) );
			// sets edit cursor to none
			EditCursor.cursorOperation = EditCursor.CURSOR_OP_NONE;
			Globals.g_app.editing = false;
			Globals.g_app.toolOrBlockEnabled = false;
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
			Log.out( "UserInventory.doDrag - What do I need to do here? ", Log.WARN );
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
				box.backgroundTexture = "assets/textures/" + (actionItem as TypeInfo).image;
		}
		else
		{
			box.data = null;
			box.backgroundTexture = "assets/textures/blank.png";
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
	override public function buildItems():void {
		name = "ItemSelector";
		
		var count:int = 0;
		// Should add what is in current inventory here.
		for  ( ; count < Slots.ITEM_COUNT;  )
		{
			buildItem( null, count++ );
		}
		
		addSelector();			
		lastItemSelection = 0;
		
		width = Slots.ITEM_COUNT * 64;
		display();
		
		//processItemSelection( noneBox );
		
//		resize(null);
	}

	private function pressItem(e:UIMouseEvent):void  {
		var box:UIObject = e.target as UIObject;
		processItemSelection( box );
	}			
	
	private function releaseItem(e:UIMouseEvent):void {
	}			
	
	public function selectByIndex( $index:int ):void {
		processItemSelection( boxes[$index] );
	}
	
	private var _editCursorModelGuid:String;
	private var _lastCursorType:int
	
	public function processItemSelection( box:UIObject ):void {
		if ( 0 < Globals.openWindowCount )
			return;
			
		moveSelector( box.x );
		var itemIndex:int = int( box.name );
		
		Globals.g_app.editing = false;
		Globals.g_app.toolOrBlockEnabled = false;
		hideGrainTools();
		// reset the cursor type to what was selected in the shape selector
		EditCursor.cursorType = _lastCursorType;
		
		if ( null != _editCursorModelGuid ) {
			//var ecm:VoxelModel = Globals.modelGet( _editCursorModelGuid );
			//if ( ecm )
				//ecm.dead = true;
			_editCursorModelGuid = null;
		}
		var oi:ObjectInfo = box.data as ObjectInfo;
		if ( oi is ObjectVoxel ) {
			var ti:ObjectVoxel = oi as ObjectVoxel;
			var selectedTypeId:int = ti.type;
			showGrainTools();
			
			if ( TypeInfo.INVALID != selectedTypeId ) {
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				EditCursor.editCursorIcon = selectedTypeId; 
				_itemMaterialSelection = itemIndex;
				Globals.g_app.editing = true;
				Globals.g_app.toolOrBlockEnabled = true;
			}
		}
		else if ( oi is ObjectAction ) {
			Log.out( "UserInventory.processItemSelection - ObjectAction");
			var oa:ObjectAction = oi as ObjectAction;
			if ( lastItemSelection != itemIndex )
			{   // We are selecting none when it was previously on another item
				oa.callBack();
			}
			else if ( - 1 != _itemMaterialSelection )// We are selecting the pick again when that is what we have already.
			{	// go back to previously used material
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				var lastBoxNone:Box = boxes[_itemMaterialSelection ];
				processItemSelection( lastBoxNone )
				return;
			}
		}
		else if ( oi is ObjectTool ) {
			Log.out( "UserInventory.processItemSelection - ObjectTool");
			var ot:ObjectTool = oi as ObjectTool;
			showGrainTools();
			if ( lastItemSelection != itemIndex )
			{   // We are selecting the pick when it was previously on another item
				ot.callBack();
			}
			else if ( - 1 != _itemMaterialSelection ) 
			{	// go back to previously used material
				Globals.g_app.editing = true;
				Globals.g_app.toolOrBlockEnabled = true;
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				var lastBoxPick:Box = boxes[_itemMaterialSelection ];
				processItemSelection( lastBoxPick );
				return;
			}
		}
		else if ( oi is ObjectModel ) {
			Log.out( "UserInventory.processItemSelection - ObjectModel - what do I do here?");
			if ( EditCursor.cursorType != EditCursor.CURSOR_TYPE_MODEL )
				_lastCursorType = EditCursor.cursorType;
			EditCursor.cursorType = EditCursor.CURSOR_TYPE_MODEL;
			var om:ObjectModel = oi as ObjectModel;
			var ii:InstanceInfo = new InstanceInfo();

			throw new Error( "UserInventory.processItemSelection - what is needed here for guid?" );
			_editCursorModelGuid = ii.modelGuid = om.modelGuid;
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
			LoadingEvent.addListener( LoadingEvent.MODEL_LOAD_COMPLETE, cursorReady );
			new ModelMaker( ii );
			Log.out( "GCI: " + ModelCacheUtils.gci );
		}
		else if ( oi is ObjectInfo ) {
			Log.out( "UserInventory.processItemSelection - ObjectInfo");
			hideGrainTools();
		}
		
		lastItemSelection = itemIndex;
	}
	
	private function cursorReady(e:LoadingEvent):void  {
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTORY ) );
		//Log.out( "UserInventory.cursorReady - ObjectModel guid: " + e.guid, Log.WARN );
	}
	
	public function onMouseWheel(event:MouseEvent):void {
		if ( 0 < event.delta ) {
			if ( lastItemSelection < (Slots.ITEM_COUNT - 1)  )
			{
				selectByIndex( lastItemSelection + 1 );
			}
			else if ( ( Slots.ITEM_COUNT -1 ) == lastItemSelection )
			{
				selectByIndex( 0 );
			}
		} else
			if ( 0 == lastItemSelection )
			{
				selectByIndex( Slots.ITEM_COUNT - 1 );
			}
			else if ( 0 < lastItemSelection )
			{
				selectByIndex( lastItemSelection - 1 );
			}
	}	
	
	static public function get lastItemSelection():int  { return _lastItemSelection; }
	static public function set lastItemSelection(value:int):void { _lastItemSelection = value; }

	public function show():void {
		_outline.visible = true;
		visible = true;
		Globals.g_app.editing = true;
		addListeners();
	}
	
	public function hide():void {
		Globals.g_app.editing = false;
		_outline.visible = false;
		visible = false;
		removeListeners();
	}
	
	private function showGrainTools():void {
		_toolSize.show();
		_shape.show();
	}
	
	private function hideGrainTools():void {
		_toolSize.hide();
		_shape.hide();
	}

	public function addListeners():void {
		//Log.out( "UserInventory.addListeners " + this + "==============================================================================" );
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
	}
	
	public function removeListeners():void {
		//Log.out( "UserInventory.removeListeners " + this + "==============================================================================" );
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
	}

	public function hotKeyInventory(e:KeyboardEvent):void {
		if  ( !Globals.active )
			return;
			
		if ( 48 <= e.keyCode && e.keyCode <= 58 )
		{
			Log.out( "UserInventory.hotKeyInventory - e.keyCode: " + e.keyCode );
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
	
	
	//public function onMouseWheel(event:MouseEvent):void
	//{
		//if ( -1 != _lastItemSelection )
		//{
			//if ( 0 < event.delta && _lastItemSelection < (Slots.ITEM_COUNT - 1)  )
			//{
				//selectByIndex( _lastItemSelection + 1 );
			//}
			//else if ( 0 < event.delta && ( Slots.ITEM_COUNT -1 ) == _lastItemSelection )
			//{
				//selectByIndex( 0 );
			//}
			//else if ( 0 > event.delta && 0 == _lastItemSelection )
			//{
				//selectByIndex( Slots.ITEM_COUNT - 1 );
			//}
			//else if ( 0 < _lastItemSelection )
			//{
				//selectByIndex( _lastItemSelection - 1 );
			//}
		//}
	//}	
	//public function onMouseWheel(event:MouseEvent):void
	//{
		//var curSelection:int = QuickInventory.currentItemSelection;
		//if ( 0 > event.delta )
		//{
			//curSelection--;
			//if ( curSelection < 0 )
				//curSelection = 9;
		//}
		//else
		//{
			//curSelection++;
			//if ( 9 < curSelection )
				//curSelection = 0;
		//}
		//processItemSelection( getBoxFromIndex( curSelection ) );
	//}		
	//
	//
}
}