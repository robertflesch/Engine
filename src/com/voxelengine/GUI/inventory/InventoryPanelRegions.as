/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

import flash.events.Event;

import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;


import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.RegionManager;

public class InventoryPanelRegions extends VVContainer
{
	// TODO need a more central location for these
	static public const REGION_CAT_PRIVATE:String = "Personal";
	static public const REGION_CAT_GROUP:String = "Group";
	static public const REGION_CAT_MANAGE:String = "Manage";
	
	private var _barUpper:TabBar;
	// This hold the items to be displayed
	private var _itemContainer:Container;
	private var _listbox1:ListBox;
	private var _createFileButton:Button		
	
	public function InventoryPanelRegions( $parent:VVContainer ) {
		super( $parent );
		width = _parent.width;
		//autoSize = true;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
//		upperTabsAdd();
		addItemContainer();
		displayAllRegions();
	}
	/*
	private function upperTabsAdd():void {
		_barUpper = new TabBar();
		_barUpper.orientation = ButtonBarOrientation.VERTICAL;
		_barUpper.name = "upper";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barUpper.addItem( LanguageManager.localizedStringGet( Globals.MODE_PUBLIC ), Globals.MODE_PUBLIC );
		_barUpper.addItem( LanguageManager.localizedStringGet( Globals.MODE_PRIVATE ), Globals.MODE_PRIVATE );
		_barUpper.addItem( LanguageManager.localizedStringGet( Globals.MODE_MANAGE ), Globals.MODE_MANAGE );
		_barUpper.setButtonsWidth( 128 );
		_barUpper.selectedIndex = 0;
		eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barUpper );
	}
*/
	private function addItemContainer():void {
		_itemContainer = new Container( width, height );
		_itemContainer.autoSize = true;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		addElement( _itemContainer );
		_listbox1 = new ListBox( width, 15 );
		_itemContainer.addElement( _listbox1 );
		eventCollector.addEvent( _listbox1, UIMouseEvent.CLICK, editThisRegion );
		RegionEvent.addListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.addListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		RegionEvent.addListener( ModelBaseEvent.CHANGED, regionInfoChanged );
	}
	
	private function regionInfoChanged(e:RegionEvent):void 
	{
		displayAllRegions();
	}
	
	//private function selectCategory(e:ListEvent):void 
	//{			
		//displaySelectedRegionList();	
	//}
	
	private function displayAllRegions():void
	{
		_listbox1.removeAll();
		RegionEvent.addListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.addListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId );
		if ( true == Globals.isDebug )
			RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC );
	}

	private function regionLoadedEvent( $re: RegionEvent ):void
	{
		var region:Region  = $re.data as Region;
		_listbox1.addItem( region.name + "\t Owner: " + region.owner + "\t Desc: " + region.desc , region.guid );
	}
	
	private function editThisRegion(event:UIMouseEvent):void 
	{
		if ( -1 == _listbox1.selectedIndex )
			return;
			
		var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
		if ( li ) {
			RegionEvent.removeListener( ModelBaseEvent.ADDED, regionLoadedEvent );
			RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
			var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_OWNED, WindowInventoryNew.INVENTORY_CAT_REGIONS );
			//new WindowRegionDetail( li.data, WindowInventoryNew, startingTab );
			new WindowRegionDetail( li.data, null );
		}
	}
	
	override protected function onRemoved( event:UIOEvent ):void {
		RegionEvent.removeListener( ModelBaseEvent.ADDED, regionLoadedEvent );
		RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
		RegionEvent.removeListener( ModelBaseEvent.CHANGED, regionInfoChanged );
	}
}
}
