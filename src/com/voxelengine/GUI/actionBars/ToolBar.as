/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.GUI.VVCanvas;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.events.VVMouseEvent;
import com.voxelengine.renderer.Renderer;

import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import org.flashapi.swing.event.ImageEvent;
	
	import org.flashapi.swing.Box;
	import org.flashapi.swing.Image;
    import org.flashapi.swing.event.UIMouseEvent;
    import org.flashapi.swing.event.UIOEvent;
	import org.flashapi.swing.core.UIObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	 
	public class ToolBar extends VVCanvas	
	{
		private var TOOLBAROUTLINE_WIDTH:int = 800;
		private var TOOLBAROUTLINE_HEIGHT:int = 136;
		protected const IMAGE_SIZE:int = 64;
		
		protected var _itemInventory:QuickInventory = null;
		
		private const ITEM_COUNT:int = 10;
		
		public function ToolBar( $assetName:String )
		{
			var outline:Image = new Image( Globals.texturePath + $assetName );
			outline.addEventListener(ImageEvent.IMAGE_LOADED, imageLoaded );
			addElement( outline );
			
			_itemInventory = new QuickInventory(800,126, 64, "beastToolbar.png");
			addChild(_itemInventory);

			display( 0, Renderer.renderer.height - TOOLBAROUTLINE_HEIGHT );
		}
		
		// This listens to all events generated by the toolbar.
		//override public function dispatchEvent(event:Event):Boolean
		//{
			//trace(event.type);
			//return super.dispatchEvent(event);
		//}
		
		private function imageLoaded( event:ImageEvent):void
		{
			// These have to be AFTER display for some odd reason or they wont work.
			resizeToolBar( null );
			
			addListeners();
			buildActions();
			
			event.target.removeEventListener(ImageEvent.IMAGE_LOADED, imageLoaded );
		}
		
		private function onRemoved( event:UIOEvent ):void
 		{
			removeListeners();
			_itemInventory.remove();
			_itemInventory = null;
			eventCollector.removeAllEvents();
		}
		
		public function addListeners():void
		{
			VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, hotKeyItem );
			VVMouseEvent.addListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
			Globals.g_app.stage.addEventListener( Event.RESIZE, resizeToolBar );
			addEventListener(UIOEvent.REMOVED, onRemoved );
		}
		
		public function removeListeners():void
		{
			VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, hotKeyItem );
			VVMouseEvent.removeListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
			Globals.g_app.stage.removeEventListener( Event.RESIZE, resizeToolBar );
			removeEventListener(UIOEvent.REMOVED, onRemoved );
		}
		
		protected function mouseDown(e:MouseEvent):void {
			throw new Error( "ToolBar.mouseDown - Must be overriden" );
		}
		// Dont call this until after bar is displayed
		public function buildActions():void	{
			throw new Error( "ToolBar.buildActions - Must be overriden" );
		}
		public function processItemSelection( box:UIObject ):void 
		{
			throw new Error( "ToolBar.processItemSelection - Must be overriden" );
		}
		public function activateItemSelection( box:UIObject ):void 
		{
			throw new Error( "ToolBar.activateItemSelection - Must be overriden" );
		}
		
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Inventory and ToolSize
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//public function buildAction( actionItem:ObjectInfo, count:int ):Box
		//{
			//var buildResult:Object = _itemInventory.buildItem( actionItem, count, "" );
			//eventCollector.addEvent( buildResult.box, UIMouseEvent.PRESS, pressItem );
			//eventCollector.addEvent( buildResult.hotkey, UIMouseEvent.PRESS, pressItem );
			//return buildResult.box;
		//}
		
		public function show():void {
			this.visible = true;
			_itemInventory.visible = true;
		}
		
		public function hide():void {
			this.visible = false;
			_itemInventory.visible = false;
		}
		
		private function pressItem(e:UIMouseEvent):void {
			var box:UIObject = e.target as UIObject;
			processItemSelection( box );
			activateItemSelection( box );
		}			
		
		private function selectItemByIndex( index:int ):void
		{
			//Log.out( "ToolBar.selectItemByIndex: " + index );
			var box:Box = _itemInventory.boxes[ index ];
			_itemInventory.moveSelector( box );
			processItemSelection( box );
		}
		
		public function hotKeyItem(e:KeyboardEvent):void 
		{
			if  ( !Globals.active || Globals.openWindowCount )
				return;
				
			//Log.out( "ToolBar.hotKeyItem: " + (e.keyCode - 49) );
			if ( 48 <= e.keyCode && e.keyCode <= 58 )
			{
				var selectedItem:int = e.keyCode - 48;
				var box:Box = _itemInventory.boxes[ index ];
				_itemInventory.moveSelector( box );
				processItemSelection( box );
				activateItemSelection( box );
			}
		}
		
		protected function onMouseWheel(event:MouseEvent):void
		{
			if  ( !Globals.active )
				return;
				
			var curSel:int = QuickInventory.currentItemSelection;
			if ( -1 != curSel )
			{
				if ( 0 < event.delta && curSel < (ITEM_COUNT - 1)  )
				{
					selectItemByIndex( curSel + 1 );
				}
				else if ( 0 < event.delta && ( ITEM_COUNT -1 ) == curSel )
				{
					selectItemByIndex( 0 );
				}
				else if ( 0 > event.delta && 0 == curSel )
				{
					selectItemByIndex( ITEM_COUNT - 1 );
				}
				else if ( 0 < curSel )
				{
					selectItemByIndex( curSel - 1 );
				}
			}
		}
		
		public function resizeToolBar(event:Event):void 
		{
			var halfRW:int = Renderer.renderer.width / 2;
			var halfRH:int = Renderer.renderer.height / 2;

			_itemInventory.y = Renderer.renderer.height - (_itemInventory.height );
			_itemInventory.x = (halfRW  -  320);
			
			y = Renderer.renderer.height - TOOLBAROUTLINE_HEIGHT;
			x = halfRW - (TOOLBAROUTLINE_WIDTH / 2);
		}
	}
}