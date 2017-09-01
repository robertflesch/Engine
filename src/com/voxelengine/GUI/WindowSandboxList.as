/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{

import flash.events.Event;

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.VVWindowEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;

public class WindowSandboxList extends VVPopup
{
	static private const WIDTH:int = 200;
	static private const TITLE:String = "Sandbox List";
	
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
	
	
	private var _listBox1:ListBox = new ListBox( WIDTH, 15 );
	private var _manageRegionButton:Button;
	private var _loadRegionButton:Button;
	private var _createFileButton:Button;
	private var _deleteFileButton:Button;

	public function WindowSandboxList()
	{
		super(TITLE);
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		showCloseButton = false;

		var bar:TabBar = new TabBar();
		bar.setButtonsWidth( WIDTH/3 );
		bar.addItem( Globals.MODE_PUBLIC );
		bar.addItem( Globals.MODE_PRIVATE );
		var openType:String = Globals.mode;
		if ( Globals.MODE_PUBLIC == openType )
			bar.selectedIndex = 0;
		else if ( Globals.MODE_PRIVATE == openType ) 	
			bar.selectedIndex = 1;
		else
			bar.selectedIndex = 2;
			
		addGraphicElements( bar );
		eventCollector.addEvent( bar, ListEvent.ITEM_CLICKED, selectCategory );

		addElement(new Label( "Click Sandbox to load" ));
		addElement( _listBox1 );

		var _buttonPanel:Container = new Container( WIDTH, 20);

		_loadRegionButton = new Button( "Load" );
		_buttonPanel.addElement( _loadRegionButton );
		eventCollector.addEvent( _loadRegionButton , UIMouseEvent.CLICK , loadRegion );
		_loadRegionButton.visible = false;

		_createFileButton = new Button( "Create" );
		_buttonPanel.addElement( _createFileButton );
		eventCollector.addEvent( _createFileButton , UIMouseEvent.CLICK , createRegion );
		_createFileButton.visible = false;

		_deleteFileButton = new Button( "Delete" );
		_buttonPanel.addElement( _deleteFileButton );
		eventCollector.addEvent( _deleteFileButton , UIMouseEvent.CLICK , deleteRegion );
		_deleteFileButton.visible = false;

		_manageRegionButton = new Button( "Manage" );
		_buttonPanel.addElement( _manageRegionButton );
		eventCollector.addEvent( _manageRegionButton , UIMouseEvent.CLICK , manageRegion );
		_manageRegionButton.visible = false;
		addElement( _buttonPanel );


		// Event handlers
//		eventCollector.addEvent( _listBox1, UIMouseEvent.CLICK, loadThisRegion );

		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
		
		RegionEvent.addListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.addListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		
		displaySelectedRegionList( openType );
		
		display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function createRegion(e:UIMouseEvent):void {
		new WindowRegionDetail( null, WindowSandboxList );
		remove();
	}

	private function deleteRegion(e:UIMouseEvent):void {
		var li:ListItem = getSelectedItem();
		if ( li ) {
			RegionEvent.create(ModelBaseEvent.DELETE, 0, li.data);
			displaySelectedRegionList( type )
		}
	}

	private function manageRegion(e:UIMouseEvent):void {
		var li:ListItem = getSelectedItem();
		if ( li ) {
			new WindowRegionDetail( li.data, WindowSandboxList );
			remove();
		}
	}

	private function loadRegion(event:UIMouseEvent):void {
		var li:ListItem = getSelectedItem();
		if ( li ) {
			RegionEvent.create( RegionEvent.JOIN, 0, li.data );
			remove();
		}
	}

	private function getSelectedItem():ListItem {
		if ( _listBox1 && -1 == _listBox1.selectedIndex )
			return null;
		return _listBox1.getItemAt( _listBox1.selectedIndex );
	}

	private function selectCategory(e:ListEvent):void {
		displaySelectedRegionList( e.target.value );	
	}

	override protected function onRemoved( event:UIOEvent ):void {
		super.onRemoved( event );
		RegionEvent.removeListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		
		Globals.g_app.dispatchEvent( new VVWindowEvent( VVWindowEvent.WINDOW_CLOSING, label ) );
		_s_currentInstance = null;
	}


	private function displaySelectedRegionList( type:String ):void
	{
		const startingState:Boolean = true;
		_createFileButton.visible = startingState;
		_deleteFileButton.visible = startingState;
		_loadRegionButton.visible = startingState;
		_manageRegionButton.visible = startingState;
		_listBox1.removeAll();
		Globals.mode = type;
		if ( Globals.MODE_PRIVATE == type ) {
			RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId );
			_createFileButton.visible = true;
			_deleteFileButton.visible = true;
			_loadRegionButton.visible = true;
			_manageRegionButton.visible = true;
		} else if ( Globals.MODE_PUBLIC == type ) {
			_createFileButton.visible = false;
			_deleteFileButton.visible = false;
			_loadRegionButton.visible = true;
			_manageRegionButton.visible = false;
			RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC );
		}
	}

	private function regionLoadedEvent( $re: RegionEvent ):void
	{
		var region:Region  = $re.data as Region;
		
		//Log.out( "WindowSandboxList.regionLoadedEvent - adding regionId: " + region.toString() );
		if ( Globals.MODE_PRIVATE == Globals.mode )
		{
			if ( Network.userId == region.owner )
				_listBox1.addItem( region.name, region.guid );
		}
		else if ( Globals.MODE_PUBLIC == Globals.mode )
		{
			if ( Network.PUBLIC == region.owner )
				_listBox1.addItem( region.name, region.guid );
		}
		else // ManageMode
		{
			_listBox1.addItem( region.name, region.guid );
		}
	}
	
}
}