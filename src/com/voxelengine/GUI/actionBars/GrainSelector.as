/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;

import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.UIMouseEvent;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.models.EditCursor;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.inventory.ObjectGrain;
import com.voxelengine.worldmodel.inventory.ObjectInfo;

public class GrainSelector extends QuickInventory
{
	private static var s_currentItemSelection:int = -1;
	public static function get currentItemSelection():int { return s_currentItemSelection }
	public static function set currentItemSelection(val:int):void { s_currentItemSelection = val; }
	
	private static var _lastGrainSelection:int = -1;
	
	public function GrainSelector() {
		// These numbers come from the size of the artwork, and from the size of the toolbar below it.
		super( 244, 42, 32, "grainSelector.png", 84 );
		_selectorXOffset = 10; // From image of "grainSelector.png"
		buildItems();
		display();
		show();
		resizeObject( null );
	}
	
	public function addListeners():void
	{
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
	}
	
	public function removeListeners():void
	{
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
	}

	public function show():void
	{
		_outline.visible = true;
		visible = true;
		addListeners();
	}
	
	public function hide():void
	{
		_outline.visible = false;
		visible = false;
		removeListeners();
	}
	
	public function hotKeyInventory(e:KeyboardEvent):void 
	{
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
	
	
	private function buildItem( $item:ObjectInfo, count:int ):Box {
		var item:ObjectGrain = $item as ObjectGrain;
		var box:Box = new Box(_imageSize, _imageSize);
		var hk:Label = new Label("", 20);
		box.x = _imageSize * count  + _selectorXOffset;
		box.y = height - _imageSize;
		box.name = String( count );
		box.data = item;
		box.backgroundTexture = "assets/textures/" + item.image;
		addElement( box );
		
		hk.data = item;
		hk.x = _imageSize * count + _selectorXOffset + 5;
		hk.fontColor = 0xffffff;
		hk.text = "F" + String( count  + 1 );  // 0 box is F1 key
		addElement(hk);
		
		eventCollector.addEvent( box, UIMouseEvent.PRESS, pressGrain );
		eventCollector.addEvent( box, UIMouseEvent.RELEASE, releaseGrain );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressGrain );
		eventCollector.addEvent( hk, UIMouseEvent.RELEASE, releaseGrain );
		
		//return { box: box, hotkey:hk };
		return box;
	}
	
	override public function buildItems():void
	{
		name = "GrainSelector";

		var count:int = 0;
		var ti:ObjectGrain = new ObjectGrain( "0", "0.0625meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "1", "0.125meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "2", "0.25meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "3", "0.5meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "4", "1meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "5", "2meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		ti = new ObjectGrain( "6", "4meter.png" );
		boxes[count] = buildItem( ti, count++ );
		
		//width = 7 * 64;
		//grainAction( 4 );
		addSelector();			
		processGrainSelection( boxes[4] );
	}
	
	private function pressGrain(e:UIMouseEvent):void 
	{
		var box:UIObject = e.target as UIObject;
		processGrainSelection( box );
	}			
		
	private function releaseGrain(e:UIMouseEvent):void 
	{
	}			
	
	public function processGrainSelection( box:UIObject ):void 
	{
		var ti:ObjectGrain = box.data as ObjectGrain;
		EditCursor.editCursorSize = int ( ti.name.toLowerCase() );
		moveSelector( box.x );

		
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
	
	public function selectByIndex( index:int ):void
	{
		processGrainSelection( boxes[ index ] );
	}
	
	public function onMouseWheel(event:MouseEvent):void
	{
		if ( event.ctrlKey ) {
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
			processGrainSelection( boxes[ curSelection ] );
		}
	}		
}
}