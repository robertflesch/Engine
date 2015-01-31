/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.ObjectInfo;
import flash.display.Sprite;
import flash.filters.GlowFilter;

import org.flashapi.swing.Canvas;
import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.constants.*;

import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.Globals;
import com.voxelengine.Log;

	import org.flashapi.swing.dnd.*;
	import org.flashapi.swing.UIManager;
	import org.flashapi.swing.event.DnDEvent;
	import org.flashapi.swing.event.UIMouseEvent;
	import org.flashapi.swing.core.UIObject;
	import flash.display.DisplayObject;


public class QuickInventory extends VVCanvas
{
	private var _dragOp:DnDOperation = new DnDOperation();
	private static var s_currentItemSelection:int = -1;
	public static function get currentItemSelection():int { return s_currentItemSelection }
	public static function set currentItemSelection(val:int):void { s_currentItemSelection = val; }
	
	private const IMAGE_SIZE:int = 64;
	private var _selector:Sprite = new Canvas(IMAGE_SIZE, IMAGE_SIZE);
	public var _boxes:Vector.<BoxInventory> = new Vector.<BoxInventory>(10,true);
	
	public function QuickInventory() {
		super( 256, IMAGE_SIZE );
		layout = new AbsoluteLayout();
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_CANCELED, cancel );
		//eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP, drop );
		//eventCollector.addEvent(_dragOp, DnDEvent.DND_COMPLETE, drop );
		//eventCollector.addEvent(_dragOp, DnDEvent.DND_FINISH, drop );
		//eventCollector.addEvent(_dragOp, DnDEvent.DND_EXIT, drop );
	}
////////////////////////////////
		//private function drop(e:DnDEvent):void 
		//{
			//if ( e.dragOperation.initiator.data is TypeInfo ) {
				//Log.out( "QuickInventory.drop  -typeInfo ", Log.WARN );
			//}
			//else if ( e.dragOperation.initiator.data is ObjectInfo ) {
				//Log.out( "QuickInventory.drop  - objectInfo ", Log.WARN );
				//
			//}
		//}
		
		private function cancel(e:DnDEvent):void 
		{
			if ( e.dragOperation.initiator is BoxInventory )
			{
				var bi:BoxInventory = e.dragOperation.initiator as BoxInventory;
				var slotId:int = int( bi.name );
				bi.reset();
				InventoryManager.dispatch( new InventorySlotEvent( InventorySlotEvent.INVENTORY_SLOT_CHANGE, Network.userId, slotId, null ) );
			}
		}
		
		private function dropMaterial(e:DnDEvent):void 
		{
			if ( e.dropTarget is BoxInventory && e.dragOperation.initiator is BoxInventory )
			{
				(e.dropTarget as BoxInventory).updateObjectInfo( e.dragOperation.initiator.data );
				(e.dragOperation.initiator as BoxInventory).reset();
				
			}
			//if ( e.dragOperation.initiator.data is TypeInfo )
			//{
				//e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
				//e.dropTarget.data = e.dragOperation.initiator.data;
				//
				//
				//if ( e.dropTarget.target is PanelMaterials ) {
					//Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				//}
				//else if ( e.dropTarget.target is PanelBonuses ) {
					//Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
					//e.dropTarget.backgroundTextureManager.resize( 32, 32 );
				//}
			//}
		}
		
		private function doDrag(e:UIMouseEvent):void 
		{
			_dragOp.initiator = e.target as UIObject;
			_dragOp.dragImage = e.target as DisplayObject;
			// this adds a drop format, which is checked again what the target is expecting
			if ( e.target.data && e.target.data.category ) {
				_dragOp.resetDropFormat();
				var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
				_dragOp.addDropFormat( dndFmt );
			}
			
			UIManager.dragManager.startDragDrop(_dragOp);
		}			
		
////////////////////////////////
	
	public function addTypeAt( ti:TypeInfo, slot:int ):void {
		var box:Box = getBoxFromIndex( slot );
		box.backgroundTexture = ti.image;
		box.data = ti;
	}
	
	public function getBoxFromIndex( index:int ):Box {
		var selectedItem:int = index * 2;
		//var el:Element  = getElementAt( selectedItem );
		//var box:Box = el.getElement() as Box;
		var box:Box = getObjectAt( selectedItem ) as Box;
		return box;
	}
	
	public function getIndexFromBox( box:Box ):int {
		var index:int = box.x / IMAGE_SIZE;
		return index;
	}
	
	public function addSelector():void {
		_selector = new Sprite();
		_selector.filters = [new GlowFilter(0xff0000, .5)];
		with (_selector.graphics) {
			lineStyle(2, 0xff0000, .5);
			drawRect(2, 2, 61, 61);
			endFill();
		}
		addElement(_selector);
	}
	
	public function moveSelector( x:int ):void {
		_selector.x = x;
		QuickInventory.currentItemSelection = x/IMAGE_SIZE;
		//Log.out( "QuickInventory index of selected: " + QuickInventory.currentItemSelection );
	}
	
	public function buildActionItem( actionItem:ObjectInfo, count:int ):Object {
		//var box:Box = new Box(IMAGE_SIZE, IMAGE_SIZE);
		var box:BoxInventory = new BoxInventory(64, 64, BorderStyle.NONE, actionItem );
		eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

		_boxes[count] = box;
		var hk:Label = new Label("", 20);
		box.x = IMAGE_SIZE * count;
		box.y = 0;
		box.name = String( count );
		if ( actionItem && actionItem.image )
		{
			box.data = actionItem;
			box.backgroundTexture = "assets/textures/" + actionItem.image;
		}
		else
		{
			box.data = null;
			box.backgroundTexture = "assets/textures/blank.png";
			box.dropEnabled = true;
		}
		addElement( box );
		
		hk.x = IMAGE_SIZE * count;
		hk.fontColor = 0xffffff;
		if ( count == 10 )
			hk.text = "0";
		else	
			hk.text = String( count + 1 );
		addElement(hk);
		
		return { box: box, hotkey:hk };
	}
	
	
	public function buildGrain( item:ObjectInfo, count:int, shortCutImage:String):Object {
		var box:Box = new Box(IMAGE_SIZE, IMAGE_SIZE);
		var hk:Label = new Label("", 20);
		box.x = IMAGE_SIZE * (count - 1);
		box.y = 0;
		box.name = String( count );
		box.data = item;
		box.backgroundTexture = "assets/textures/" + item.image;
		addElement( box );
		
		hk.data = item;
		hk.x = IMAGE_SIZE * (count - 1);
		hk.fontColor = 0xffffff;
		hk.text = "F" + String( count );
		addElement(hk);
		
		return { box: box, hotkey:hk };
	}
}
}