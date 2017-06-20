/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{

import com.voxelengine.events.VVMouseEvent;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import org.flashapi.swing.Label;
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.UIMouseEvent;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.CursorSizeEvent;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.worldmodel.inventory.ObjectGrain;
import com.voxelengine.worldmodel.inventory.ObjectInfo;

public class GrainSelector extends QuickInventory
{
	private var _currentSize:int = 4;
	
	public function GrainSelector() {
		// These numbers come from the size of the artwork, and from the size of the toolbar below it.
		super( 244, 42, 32, "grainSelector.png", 84 );
		_selectorXOffset = 10; // From image of "grainSelector.png"
		buildItems();
	}
	
	public function addListeners():void {
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
		VVMouseEvent.addListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
		CursorSizeEvent.addListener( CursorSizeEvent.SET, onSizeSet );
	}
	
	public function removeListeners():void {
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
		VVMouseEvent.removeListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
		CursorSizeEvent.removeListener( CursorSizeEvent.SET, onSizeSet );
	}
	
	private function onSizeSet(e:CursorSizeEvent):void 
	{
		var cursorSize:String = String( e.size );
		for each ( 	var box:BoxInventory in _boxes )
			if ( box && box.name == cursorSize ) {
				_selector.x = box.x;
				_selector.y = height - _imageSize;
				currentItemSelection = ( x - _selectorXOffset) / _imageSize;
				break;
			}
		//Log.out( "QuickInventory index of selected: " + QuickInventory.currentItemSelection );
	}

	public function show():void {
		_outline.visible = true;
		visible = true;
		addListeners();
		CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, _currentSize ) );
		display();
		resizeObject( null );
	}
	
	public function hide():void {
		_outline.visible = false;
		visible = false;
		removeListeners();
	}
	
	public function hotKeyInventory(e:KeyboardEvent):void {
		if  ( !Globals.active )
			return;
		if ( 112 <= e.keyCode && e.keyCode <= 118 )
		{
			var selectedGrain:int = e.keyCode - 112;
			selectByIndex( selectedGrain );
		}
		//else if ( 119 == e.keyCode )
		//{
			//_shape.pressShapeHotKey(e);
		//}
	}
	
	
	private function buildItem( $item:ObjectInfo, count:int ):BoxInventory {
		var item:ObjectGrain = $item as ObjectGrain;
		var box:BoxInventory = new BoxInventory(_imageSize, _imageSize);
		var hk:Label = new Label("", 20);
		box.x = _imageSize * count  + _selectorXOffset;
		box.y = height - _imageSize;
		box.name = String( count );
		box.data = item;
		box.backgroundTexture = "assets/textures/" + item.image;
		addElement( box );
		
		hk.data = item;
		hk.x = _imageSize * count + _selectorXOffset + 5;
		hk.y = -4;
		hk.fontColor = 0xffffff;
		hk.text = "F" + String( count  + 1 );  // 0 box is F1 key
		addElement(hk);
		
		eventCollector.addEvent( box, UIMouseEvent.PRESS, pressGrain );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressGrain );
		
		//return { box: box, hotkey:hk };
		return box;
	}
	
	override protected function buildItems():void {
		var count:int = 0;
		var ti:ObjectGrain = new ObjectGrain( null, "0", "0.0625meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "1", "0.125meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "2", "0.25meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "3", "0.5meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "4", "1meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "5", "2meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		ti = new ObjectGrain( null, "6", "4meter.png" );
		boxes[count] = buildItem( ti, count );
		ti.box = boxes[count++];
		
		addSelector();			
		// start off highlighting 1 meter
		processGrainSelection( boxes[4] );
		//Log.out( "GrainSelector.buildItems exit" );
	}
	
	private function pressGrain(e:UIMouseEvent):void { processGrainSelection( e.target as UIObject ); }			
	public function selectByIndex( index:int ):void { processGrainSelection( boxes[ index ] ); }
	
	public function onMouseWheel(event:MouseEvent):void {
		if ( event.ctrlKey ) {
			var curSelection:int = QuickInventory.currentItemSelection;
			if ( 0 > event.delta )
				curSelection--;
			else
				curSelection++;

			if ( curSelection < 0 )
				curSelection = 0;
			if ( 6 < curSelection )
				curSelection = 6;	
			processGrainSelection( boxes[ curSelection ] );
		}
	}		
	
	public function processGrainSelection( $box:UIObject ):void {
		var ti:ObjectGrain = $box.data as ObjectGrain;
		_currentSize = int ( ti.name.toLowerCase() );
		CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, _currentSize ) );
		//Log.out( "GrainSelector.processGrainSelection exit" );
	}
}
}