/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
import flash.events.Event;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.dnd.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RegionLoadedEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Persistance;
import com.voxelengine.server.VVServer;
import com.voxelengine.worldmodel.Region;

public class WindowSandboxList extends VVPopup
{
	static private const WIDTH:int = 200;
	
	static private var _s_currentInstance:WindowSandboxList = null;
	static public function get isActive():Boolean { return null != _s_currentInstance; }
	static public function create():WindowSandboxList 
	{  
		if ( null == _s_currentInstance )
			new WindowSandboxList();
		return _s_currentInstance; 
	}
	
	private var _listbox1:ListBox = new ListBox( WIDTH, 15 );
	private var _createFileButton:Button		
	
	public function WindowSandboxList()
	{
		super("Sandbox List");
		var openType:String = Globals.mode;
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		closeButtonActive = false;

		var bar:TabBar = new TabBar();
		bar.setButtonsWidth( WIDTH/2 );
		bar.addItem( Globals.MODE_PUBLIC );
		bar.addItem( Globals.MODE_PRIVATE );
		addGraphicElements( bar );
		eventCollector.addEvent( bar, ListEvent.ITEM_CLICKED, selectCategory );
		eventCollector.addEvent( bar, ListEvent.ITEM_PRESSED, pressCategory );

		addElement(new Label( "Click Sandbox to load" ));
		addElement( _listbox1 );
		
		var buttonPanel:Container = new Container( WIDTH, 20);
		_createFileButton = new Button( "Create" );
		buttonPanel.addElement( _createFileButton );
		addElement( buttonPanel );
		eventCollector.addEvent( _createFileButton , UIMouseEvent.CLICK
							   , createRegion )
		
		// Event handlers
		eventCollector.addEvent( _listbox1, UIMouseEvent.CLICK, loadthisRegion );
		//eventCollector.addEventListener( _listbox1, ListEvent.LIST_CHANGED, selectSandbox);
		// These events are needed to keep mouse clicks from leaking thru window
		// This needs to be handled by stage
		eventCollector.addEvent( this, UIMouseEvent.CLICK, windowClick );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		eventCollector.addEvent( this, UIMouseEvent.PRESS, pressWindow );
		
		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
		Globals.g_app.addEventListener( RegionLoadedEvent.REGION_LOADED, regionLoadedEvent );
		
		if ( bar )
		{
			bar.selectedIndex = 0;
		}
		displaySelectedRegionList( openType );
		
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function createRegion(e:UIMouseEvent):void
	{
		new WindowRegionNew();
		remove();
	}
	
	private function selectCategory(e:ListEvent):void 
	{			
		displaySelectedRegionList( e.target.value );	
	}
	protected function onResize(event:Event):void
	{
		move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
	}
	
	// Window events
	private function onRemoved( event:UIOEvent ):void
	{
		Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize);
		Globals.g_app.removeEventListener( RegionLoadedEvent.REGION_LOADED, regionLoadedEvent );

		eventCollector.removeAllEvents();
		_s_currentInstance = null;
	}
	
	private function onClickSandBox(event:UIMouseEvent):void 
	{
		loadthisRegion( null );
	}
	
	private function loadthisRegion(event:UIMouseEvent):void 
	{
		if ( -1 == _listbox1.selectedIndex )
			return;
			
		var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
		if ( li && li.data )
		{
			VVServer.joinRoom( li.data );
		}
		remove();
	}
	
	private function displaySelectedRegionList( type:String ):void
	{
//		_listbox1.removeAll();
		if ( Globals.MODE_PRIVATE == Globals.mode )
		{
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REQUEST_PRIVATE, "" ) );
		}
		else if ( Globals.MODE_PUBLIC == Globals.mode )
		{
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REQUEST_PUBLIC, "" ) );
		}
	}

	private function regionLoadedEvent( e: RegionLoadedEvent ):void
	{
		var region:Region = e.region;
		
//		Log.out( "WindowSandboxList.regionLoadedEvent - adding regionId: " + region.toString() );
		if ( Globals.MODE_PRIVATE == Globals.mode )
		{
			if ( Network.userId == region.owner )
				_listbox1.addItem( region.name, region.regionId );
		}
		else if ( Globals.MODE_PUBLIC == Globals.mode )
		{
			if ( Persistance.DB_PUBLIC == e.region.owner )
				_listbox1.addItem( region.name, region.regionId );
		}
	}
	
	private function pressWindow(e:UIMouseEvent):void
	{
		//Log.out( "WindowInventory.pressWindow" );
	}
	private function windowClick(e:UIMouseEvent):void
	{
		//Log.out( "WindowInventory.windowClick" );
	}
	private function pressCategory(e:UIMouseEvent):void
	{
		//Log.out( "WindowInventory.pressCategory" );
	}
}
}