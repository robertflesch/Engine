/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.VVWindowEvent;
import flash.events.Event;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.RegionManager;

public class WindowSandboxList extends VVPopup
{
	static private const WIDTH:int = 200;
	static public const WINDOWSANDBOXLIST_TITLE:String = "Sandbox List";
	
	static private var _s_currentInstance:WindowSandboxList = null;
	static public function get isActive():Boolean { return null != _s_currentInstance; }
	static public function create():WindowSandboxList 
	{  
		if ( null == _s_currentInstance )
			new WindowSandboxList();
		return _s_currentInstance; 
	}
	
	// Listener is added in VoxelVerseGUI constuctor
	static public function listenForLoginSuccess( $e:LoginEvent ):void {
		// See if a region has been specified, if not, show user a list
		if ( null == $e.guid ) {
			if ( !WindowSandboxList.isActive )
				WindowSandboxList.create();
		}
	}
	
	
	private var _listbox1:ListBox = new ListBox( WIDTH, 15 );
	private var _createFileButton:Button		
	
	public function WindowSandboxList()
	{
		super(WINDOWSANDBOXLIST_TITLE);
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		closeButtonActive = false;

		var bar:TabBar = new TabBar();
		bar.setButtonsWidth( WIDTH/3 );
		bar.addItem( Globals.MODE_PUBLIC );
		bar.addItem( Globals.MODE_PRIVATE );
		bar.addItem( Globals.MODE_MANAGE );
		var openType:String = Globals.mode;
		if ( Globals.MODE_PUBLIC == openType )
			bar.selectedIndex = 0;
		else if ( Globals.MODE_PRIVATE == openType ) 	
			bar.selectedIndex = 1;
		else
			bar.selectedIndex = 2;
			
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
		eventCollector.addEvent( this, UIMouseEvent.PRESS, pressWindow );
		
		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
		
		RegionEvent.addListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.addListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		
		displaySelectedRegionList( openType );
		
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function createRegion(e:UIMouseEvent):void
	{
		new WindowRegionDetail( null, WindowSandboxList );
		remove();
	}
	
	private function selectCategory(e:ListEvent):void 
	{			
		displaySelectedRegionList( e.target.value );	
	}

	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
		RegionEvent.removeListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		
		Globals.g_app.dispatchEvent( new VVWindowEvent( VVWindowEvent.WINDOW_CLOSING, label ) );
		_s_currentInstance = null;
	}
	
	private function loadthisRegion(event:UIMouseEvent):void 
	{
		//Log.out( "WindowSandboxList.loadthisRegion - _listbox1.selectedIndex: " + _listbox1.selectedIndex, Log.WARN );
		if ( -1 == _listbox1.selectedIndex )
			return;
			
		var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
		if ( li )
		{
			if ( Globals.MODE_PRIVATE != Globals.mode && Globals.MODE_PUBLIC != Globals.mode ) {
				new WindowRegionDetail( li.data, WindowSandboxList );
				remove();
				return;
			}
			
			if ( li.data )
				RegionEvent.dispatch( new RegionEvent( RegionEvent.JOIN, 0, li.data ) ); 
			else
				Log.out( "WindowSandboxList.loadthisRegion - NO REGION GUID FOUND", Log.ERROR );
		}
		remove();
	}
	
	private function displaySelectedRegionList( type:String ):void
	{
		_listbox1.removeAll();
		Globals.mode = type;
		if ( Globals.MODE_PRIVATE == type )
		{
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId ) );
		}
		else if ( Globals.MODE_PUBLIC == type )
		{
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC ) );
		}
		else
		{
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId ) );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC ) );
		}
	}

	private function regionLoadedEvent( $re: RegionEvent ):void
	{
		var region:Region  = $re.region;
		
		//Log.out( "WindowSandboxList.regionLoadedEvent - adding regionId: " + region.toString() );
		if ( Globals.MODE_PRIVATE == Globals.mode )
		{
			if ( Network.userId == region.owner )
				_listbox1.addItem( region.name, region.guid );
		}
		else if ( Globals.MODE_PUBLIC == Globals.mode )
		{
			if ( Network.PUBLIC == region.owner )
				_listbox1.addItem( region.name, region.guid );
		}
		else // ManageMode
		{
			_listbox1.addItem( region.name, region.guid );
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