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
import com.voxelengine.events.PersistenceEvent;
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
	private var _dataSource:String;

	
	public function InventoryPanelRegions( $parent:VVContainer, $dataSource:String ) {
		super( $parent );
        _dataSource = $dataSource;
		width = _parent.width;
		//autoSize = true;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
//		upperTabsAdd();
		addItemContainer();
        RegionEvent.addListener( ModelBaseEvent.ADDED, regionLoadedEvent );
        RegionEvent.addListener( ModelBaseEvent.RESULT, regionLoadedEvent );
        displaySelectedSource( $dataSource );
	}

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
	
	private function regionInfoChanged(e:RegionEvent):void {
		for ( var i:int =0; i < _listbox1.length; i++ ){
			var item:ListItem = _listbox1.getItemAt( i );
			if ( item.data == e.guid ) {
                var region:Region = e.data as Region;
                _listbox1.updateItemAt(i, region.name + "\t Owner: " + region.owner + "\t Desc: " + region.desc, region.guid);
            }
		}
	}
	
    private function displaySelectedSource( $dataSource:String ):void {
        _listbox1.removeAll();
        if ( $dataSource == WindowInventoryNew.INVENTORY_PUBLIC )
            RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC );
        else if ( $dataSource == WindowInventoryNew.INVENTORY_OWNED )
            RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId );
        else
            RegionEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.storeId );
	}

	private function regionLoadedEvent( $re: RegionEvent ):void
	{
		var region:Region  = $re.data as Region;
		_listbox1.addItem( region.name + "\t Owner: " + region.owner + "\t Desc: " + region.desc , region.guid );
	}
	
	private function editThisRegion(event:UIMouseEvent):void  {
		if ( -1 == _listbox1.selectedIndex )
			return;
			
		var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
		if ( li ) {
			RegionEvent.removeListener( ModelBaseEvent.ADDED, regionLoadedEvent );
			RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
//			var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_OWNED, WindowInventoryNew.INVENTORY_CAT_REGIONS );
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
