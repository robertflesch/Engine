/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import org.flashapi.swing.event.WindowEvent;

import org.flashapi.swing.Box;
import org.flashapi.swing.Image;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.collector.EventCollector;
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.Container;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.GUIEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.VVWindowEvent;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.EditCursor;
import com.voxelengine.worldmodel.inventory.Inventory;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.inventory.Slots;
import com.voxelengine.worldmodel.*;
 
public class Hub extends VVCanvas
{
	private var TOOLBAROUTLINE_WIDTH:int = 748;
	private var TOOLBAROUTLINE_HEIGHT:int = 172;
	
	private var _itemInventory:QuickInventory = null;
	private var _toolSize:QuickInventory = null;
	private var _shape:ShapeSelector = null;
	
	private static var _lastItemSelection:int = -1;
	private static var _lastGrainSelection:int = -1;
	private static var _itemMaterialSelection:int = -1;
	
	
	private var _evtColl:EventCollector = new EventCollector();;
	
	public function get itemInventory():QuickInventory { return _itemInventory; }
	public function get toolSize():QuickInventory { return _toolSize; }
	
	public function Hub()
	{
		//Globals.g_app.dispatchEvent( new GUIEvent( GUIEvent.TOOLBAR_SHOW ) );
		InventoryManager.addListener( InventoryEvent.INVENTORY_LOADED, inventoryLoaded );
		this.visible = false;
	}
	
	private function inventoryLoaded(e:InventoryEvent):void {
		//Log.out( "Hub.inventoryLoaded - populate from here" , Log.WARN );
		var outline:Image = new Image( Globals.appPath + "assets/textures/" + "hub.png");
		addElement( outline );
		
		_itemInventory = new QuickInventory();
		_itemInventory.visible = false;
		addChild(_itemInventory);
		_toolSize = new QuickInventory();
		_toolSize.visible = false;
		addChild(_toolSize);
		
		_shape = new ShapeSelector();
		addChild(_shape);
		
		display( 0, Globals.g_renderer.height - 186 );

		// These have to be AFTER display for some odd reason or they wont work.
		buildGrainSizeSelector();	
		buildInventorSelector();
		_shape.addShapeSelector();			
		_shape.visible = false;
		
		resizeHub( null );
		
	//	show();
		
		var inv:Inventory = e.result as Inventory;
		var slots:Slots = inv.slots;
		
		var items:Vector.<ObjectInfo> = slots.items;
		for ( var i:int; i < Slots.ITEM_COUNT; i++ ) {
			var item:ObjectInfo = items[i];
			(_itemInventory.boxes[i] as BoxInventory).updateObjectInfo( item );
			
		}
		Globals.g_app.addEventListener( VVWindowEvent.WINDOW_CLOSING, shouldDisplay );			
	}
	
	private function shouldDisplay(e:VVWindowEvent):void 
	{
		if ( WindowSandboxList.WINDOWSANDBOXLIST_TITLE == e.windowTitle )
			show();
	}

	public function addListeners():void
	{
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
		Globals.g_app.stage.addEventListener( Event.RESIZE, resizeHub );
	}
	
	public function removeListeners():void
	{
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
		Globals.g_app.stage.removeEventListener( Event.RESIZE, resizeHub );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Inventory and ToolSize
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private function buildItem( ti:ObjectInfo, count:int ):Box
	{
		//var buildResult:Object = _itemInventory.buildItem( ti, count, String(count+1) + ".png" );
		var buildResult:Object = _itemInventory.buildActionItem( ti, count );
		_evtColl.addEvent( buildResult.box, UIMouseEvent.PRESS, pressItem );
		_evtColl.addEvent( buildResult.box, UIMouseEvent.RELEASE, releaseItem );
		_evtColl.addEvent( buildResult.hotkey, UIMouseEvent.PRESS, pressItem );
		_evtColl.addEvent( buildResult.hotkey, UIMouseEvent.RELEASE, releaseItem );
		return buildResult.box;
	}
	
	public function show():void
	{
		this.visible = true;
		_itemInventory.visible = true;
		_toolSize.visible = true;
		_shape.visible = true;
		Globals.g_app.editing = true;
		addListeners();
	}
	
	public function hide():void
	{
		Globals.g_app.editing = false;
		this.visible = false;
		_itemInventory.visible = false;
		_toolSize.visible = false;
		_shape.visible = false;
		removeListeners();
	}
	
	// Dont call this until 
	public function buildInventorSelector():void
	{
		_itemInventory.name = "ItemSelector";
		
		var count:int = 0;
		// Should add what is in current inventory here.
		for  ( ; count < Slots.ITEM_COUNT;  )
		{
			buildItem( null, count++ );
		}
		
		_itemInventory.addSelector();			
		
		_itemInventory.width = Slots.ITEM_COUNT * 64;
		_itemInventory.display();
		
		//processItemSelection( noneBox );
		
		resizeHub(null);
	}

	private function buildGrain( ti:ObjectGrain, count:int ):Box
	{
		var buildResult:Object = _toolSize.buildGrain( ti, count, "F" + String(count) + ".png" );
		_evtColl.addEvent( buildResult.box, UIMouseEvent.PRESS, pressGrain );
		_evtColl.addEvent( buildResult.box, UIMouseEvent.RELEASE, releaseGrain );
		_evtColl.addEvent( buildResult.hotkey, UIMouseEvent.PRESS, pressGrain );
		_evtColl.addEvent( buildResult.hotkey, UIMouseEvent.RELEASE, releaseGrain );
		return buildResult.box;
	}
	
	public function buildGrainSizeSelector():void
	{
		_toolSize.name = "GrainSelector";

		var count:int = 1;
		var ti:ObjectGrain = new ObjectGrain( "0", "0.0625meter.png" );
		buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "1", "0.125meter.png" );
		buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "2", "0.25meter.png" );
		buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "3", "0.5meter.png" );
		buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "4", "1meter.png" );
		var meterBox:Box = buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "5", "2meter.png" );
		buildGrain( ti, count++ );
		
		ti = new ObjectGrain( "6", "4meter.png" );
		buildGrain( ti, count++ );
		
		_toolSize.width = 7 * 64;
		_toolSize.display();
		//grainAction( 4 );
		_toolSize.addSelector();			
		processGrainSelection( meterBox );
	}

	private function pressItem(e:UIMouseEvent):void 
	{
		var box:UIObject = e.target as UIObject;
		processItemSelection( box );
	}			
	
	private function releaseItem(e:UIMouseEvent):void 
	{
	}			
	
	private function pressGrain(e:UIMouseEvent):void 
	{
		var box:UIObject = e.target as UIObject;
		processGrainSelection( box );
	}			
		
	private function releaseGrain(e:UIMouseEvent):void 
	{
	}			
	
	private function selectItemByIndex( index:int ):void
	{
		processItemSelection( _itemInventory.getBoxFromIndex( index ) );
	}
	
	private function selectGrainByIndex( index:int ):void
	{
		processGrainSelection( _toolSize.getBoxFromIndex( index ) );
	}
	
	
	public function processGrainSelection( box:UIObject ):void 
	{
		var ti:ObjectGrain = box.data as ObjectGrain;
		EditCursor.editCursorSize = int ( ti.name.toLowerCase() );
		_toolSize.moveSelector( box.x );

		
		if ( Globals.controlledModel )
		{
			// don't want movement speed to be 0, so set it to 0.5
			if ( 0 == EditCursor.editCursorSize )
				Globals.controlledModel.instanceInfo.setSpeedMultipler( 0.5 ); 
			else
				Globals.controlledModel.instanceInfo.setSpeedMultipler( EditCursor.editCursorSize * 1.5 ); 
		}
		
		if ( null != Globals.selectedModel )
		{
			var current:GrainCursor = Globals.selectedModel.editCursor.oxel.gc;
			if ( current.grain > EditCursor.editCursorSize )
				EditCursor.shrinkCursor();
			else if ( current.grain < EditCursor.editCursorSize )
				EditCursor.growCursor();
		}
	}
	
	public function processItemSelection( box:UIObject ):void 
	{
		_itemInventory.moveSelector( box.x );
		var itemIndex:int = int( box.name );
		
		Globals.g_app.editing = false;
		Globals.g_app.toolOrBlockEnabled = false;
		var oi:ObjectInfo = box.data as ObjectInfo;
		if ( oi is ObjectVoxel ) {
			var ti:ObjectVoxel = oi as ObjectVoxel;
			var selectedTypeId:int = ti.type;
			
			if ( TypeInfo.INVALID != selectedTypeId ) {
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				EditCursor.cursorColor = selectedTypeId; 
				_itemMaterialSelection = itemIndex;
				Globals.g_app.editing = true;
				Globals.g_app.toolOrBlockEnabled = true;
			}
		}
		else if ( oi is ObjectAction ) {
			Log.out( "Hub.processItemSelection - ObjectAction");
			var oa:ObjectAction = oi as ObjectAction;
			if ( _lastItemSelection != itemIndex )
			{   // We are selecting none when it was previously on another item
				oa.callBack();
			}
			else if ( - 1 != _itemMaterialSelection )// We are selecting the pick again when that is what we have already.
			{	// go back to previously used material
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				var lastBoxNone:Box = _itemInventory.getBoxFromIndex( _itemMaterialSelection );
				processItemSelection( lastBoxNone )
				return;
			}
		}
		else if ( oi is ObjectTool ) {
			Log.out( "Hub.processItemSelection - ObjectTool");
			var ot:ObjectTool = oi as ObjectTool;
			if ( _lastItemSelection != itemIndex )
			{   // We are selecting the pick when it was previously on another item
				ot.callBack();
			}
			else if ( - 1 != _itemMaterialSelection ) 
			{	// go back to previously used material
				Globals.g_app.editing = true;
				Globals.g_app.toolOrBlockEnabled = true;
				EditCursor.cursorOperation = EditCursor.CURSOR_OP_INSERT;
				var lastBoxPick:Box = _itemInventory.getBoxFromIndex( _itemMaterialSelection );
				processItemSelection( lastBoxPick );
				return;
			}
		}
		else if ( oi is ObjectInfo )
			Log.out( "Hub.processItemSelection - ObjectInfo");
		
		_lastItemSelection = itemIndex;
	}
	
	public function hotKeyInventory(e:KeyboardEvent):void 
	{
		if  ( !Globals.active )
			return;
			
		if ( 49 <= e.keyCode && e.keyCode <= 58 )
		{
			var selectedItem:int = e.keyCode - 49;
			selectItemByIndex( selectedItem );
		}
		else if ( 112 <= e.keyCode && e.keyCode <= 118 )
		{
			var selectedGrain:int = e.keyCode - 112;
			selectGrainByIndex( selectedGrain );
		}
		else if ( 119 == e.keyCode )
		{
			_shape.pressShapeHotKey(e);
		}
	}
	
	protected function onMouseWheel(event:MouseEvent):void
	{
		if  ( !Globals.active )
			return;
			
		if ( !event.ctrlKey )
		{
			if ( -1 != _lastItemSelection )
			{
				if ( 0 < event.delta && _lastItemSelection < (Slots.ITEM_COUNT - 1)  )
				{
					selectItemByIndex( _lastItemSelection + 1 );
				}
				else if ( 0 < event.delta && ( Slots.ITEM_COUNT -1 ) == _lastItemSelection )
				{
					selectItemByIndex( 0 );
				}
				else if ( 0 > event.delta && 0 == _lastItemSelection )
				{
					selectItemByIndex( Slots.ITEM_COUNT - 1 );
				}
				else if ( 0 < _lastItemSelection )
				{
					selectItemByIndex( _lastItemSelection - 1 );
				}
			}
		}
		else
		{
			var curSelection:int = QuickInventory.currentItemSelection;
			if ( 0 > event.delta )
			{
				curSelection--;
				if ( curSelection < 0 )
					curSelection = 0;
			}
			else
			{
				curSelection++;
				if ( 6 < curSelection )
					curSelection = 6;
			}
			processGrainSelection( _toolSize.getBoxFromIndex( curSelection ) );
		}
			
	}
	
	public function resizeHub(event:Event):void 
	{
		var halfRW:int = Globals.g_renderer.width / 2;
		var halfRH:int = Globals.g_renderer.height / 2;
		if ( _toolSize ) {
		_toolSize.y = Globals.g_renderer.height - (_toolSize.height * 2);
		_toolSize.x = halfRW - (_toolSize.width / 2) + 73;

		_itemInventory.y = Globals.g_renderer.height - (_itemInventory.height );
		_itemInventory.x = (halfRW  -  320);
		
		_shape.y = Globals.g_renderer.height - 128;
		_shape.x = halfRW - (_toolSize.width / 2) - 67;
		
		y = Globals.g_renderer.height - TOOLBAROUTLINE_HEIGHT;
		x = halfRW - (TOOLBAROUTLINE_WIDTH / 2);
		}
	}
}
}