/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

import org.flashapi.swing.*
import org.flashapi.swing.containers.UIContainer;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.VVUI;

import com.voxelengine.GUI.*;

public class InventoryPanelOverview extends VVContainer
{
	private static var _s_lastType:String = "";
	private var _barUpper:TabBar;
	// This hold the items to be displayed
	private var _panelContainer:Container;
	private var _sourceType:String;
	private var _underline:Box;
	private var _parentWindow:UIContainer;

	public function InventoryPanelOverview( $windowInventoryNew:UIContainer, $source:String, $tabTokens:String ) {
		_parentWindow = $windowInventoryNew;
		super( null );
		_sourceType = $source;
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;

		var index:int = $tabTokens.indexOf( ";" );
		var startingTabName:String;
		if ( -1 < index )
			startingTabName = $tabTokens.substr( 0 , index );

		if ( WindowInventoryNew.INVENTORY_CAT_LAST == startingTabName ) {
			// does last have a value? if not give it voxels
			if ( 0 == _s_lastType.length )
				_s_lastType = WindowInventoryNew.INVENTORY_CAT_VOXELS;
			startingTabName = _s_lastType;
		} else {
			_s_lastType = startingTabName;
		}

		upperTabsAdd( startingTabName );
		addEventListener( UIOEvent.RESIZED, onResized );
		displaySelectedContainer( startingTabName, _sourceType );
	}

	override protected function onResized(e:UIOEvent):void
	{
		_barUpper.setButtonsWidth( width / _barUpper.length, 36 );
		(_parentWindow as WindowInventoryNew).onResizedFromChild( e );
		//_underline.width = width;
	}

	override protected function onRemoved( event:UIOEvent ):void {

		removeEventListener( UIOEvent.RESIZED, onResized );

		_barUpper.remove();
		_barUpper = null;

		if ( _panelContainer ) {
			_panelContainer.remove();
			_panelContainer = null;
		}

		super.onRemoved( event );
	}

	private static var _s_lastSelectedIndex:int;
	private function upperTabsAdd( $startingTabName:String ):void {
		_barUpper = new TabBar();
		_barUpper.name = "upper";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_VOXELS ),		WindowInventoryNew.INVENTORY_CAT_VOXELS );
		_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_MODELS ), 		WindowInventoryNew.INVENTORY_CAT_MODELS );
		_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_REGIONS ), 		WindowInventoryNew.INVENTORY_CAT_REGIONS );
		_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_ANIMATIONS ), 	WindowInventoryNew.INVENTORY_CAT_ANIMATIONS );
		_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_RECIPES ), 		WindowInventoryNew.INVENTORY_CAT_RECIPES );
//            var role:Role = Player.player.role;
//            if ( role.modelGetFromAttic )
//                _barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_ATTIC ), WindowInventoryNew.INVENTORY_CAT_ATTIC );

		_barUpper.setButtonsWidth( 115 );
		_barUpper.height = 40;
		if ( WindowInventoryNew.INVENTORY_CAT_VOXELS == $startingTabName )
			_s_lastSelectedIndex = _barUpper.selectedIndex = 0;
		else if ( WindowInventoryNew.INVENTORY_CAT_MODELS == $startingTabName )
			_s_lastSelectedIndex = _barUpper.selectedIndex = 1;
		else if ( WindowInventoryNew.INVENTORY_CAT_REGIONS == $startingTabName )
			_s_lastSelectedIndex = _barUpper.selectedIndex = 2;
		else if ( WindowInventoryNew.INVENTORY_CAT_ANIMATIONS == $startingTabName )
			_s_lastSelectedIndex = _barUpper.selectedIndex = 3;
		else if ( WindowInventoryNew.INVENTORY_CAT_RECIPES == $startingTabName )
			_s_lastSelectedIndex = _barUpper.selectedIndex = 4;
		else if ( WindowInventoryNew.INVENTORY_CAT_LAST )
			_barUpper.selectedIndex = _s_lastSelectedIndex;

		eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barUpper );
		_underline = new Box( width, 5);
		_underline.backgroundColor = VVUI.DEFAULT_COLOR;
		addGraphicElements( _underline );

	}

	private function selectCategory(e:ListEvent):void
	{
		_s_lastType = e.target.data as String;
		displaySelectedContainer( _s_lastType,  _sourceType );
	}

	private function displaySelectedContainer( $category:String, $dataSource:String ):void
	{
		if ( _panelContainer ) {
			removeElement( _panelContainer );
			_panelContainer.remove();
		}

		if ( WindowInventoryNew.INVENTORY_CAT_VOXELS == $category )
			_panelContainer = new InventoryPanelVoxel( this, $dataSource );
		else if ( WindowInventoryNew.INVENTORY_CAT_MODELS == $category )
			_panelContainer = new InventoryPanelModel(this, $dataSource );
		else if ( WindowInventoryNew.INVENTORY_CAT_REGIONS == $category )
			_panelContainer = new InventoryPanelRegions(this, $dataSource );
		else if ( WindowInventoryNew.INVENTORY_CAT_ANIMATIONS == $category )
			_panelContainer = new InventoryPanelAnimations(this, $dataSource );
		else if ( WindowInventoryNew.INVENTORY_CAT_RECIPES == $category )
			_panelContainer = new InventoryPanelRecipes(this, $dataSource );

		addElement( _panelContainer );
	}
}
}