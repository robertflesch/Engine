/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting {

import com.voxelengine.GUI.inventory.InventoryPanelOverview;
import com.voxelengine.GUI.inventory.InventoryPanelVoxel;
import com.voxelengine.GUI.inventory.WindowInventoryNew;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.worldmodel.inventory.Voxels;

import org.as3commons.collections.Set;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import com.voxelengine.Log;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.crafting.Recipe;


public class WindowCrafting extends VVPopup
{
	private const PANEL_WIDTH:int = 200;
	private const PANEL_HEIGHT:int = 300;
	private const PANEL_BUTTON_HEIGHT:int = 200;
	
	private var _recipeList:ListBox;
	private var _selectedRecipe:Recipe;
	private var _panelRecipe:PanelRecipe;
    private var _panelUpper:PanelBase;
    private var _panelLower:InventoryPanelVoxel;

	public function WindowCrafting()
	{
		super( LanguageManager.localizedStringGet( "Crafting" ) );
		width = 150;
		height = PANEL_HEIGHT;
		layout.orientation = LayoutOrientation.VERTICAL;
        _panelUpper = new PanelBase( null, width, height );
        _panelUpper.layout.orientation = LayoutOrientation.HORIZONTAL;
        addElement( _panelUpper );


		_recipeList = new ListBox( width, 15, PANEL_HEIGHT );
		_recipeList.addEventListener( ListEvent.LIST_CHANGED, selectRecipe );
        _panelUpper.addElement( _recipeList );

        showVoxelInventory()
		// This makes sure the crafting manager is running
		display();

//        addEventListener( UIOEvent.RESIZED, onResized );
		addEventListener(UIOEvent.REMOVED, onRemoved );
		CraftingEvent.addListener( ModelBaseEvent.RESULT_RANGE, onRecipe );
        CraftingEvent.addListener( ModelBaseEvent.RESULT, onRecipe );
		CraftingEvent.create( ModelBaseEvent.REQUEST_TYPE, Network.userId, null );

    }
	
//	private function onResized(e:UIOEvent):void
//	{
//		_recipeList.height = height;
//	}

    private function showVoxelInventory():void {
        _panelLower = new InventoryPanelVoxel( null, WindowInventoryNew.INVENTORY_OWNED, false );
        addElement( _panelLower );
        InventoryVoxelEvent.create( InventoryVoxelEvent.TYPES_REQUEST, Network.userId, -1, null );
    }


    private function selectRecipe(e:ListEvent):void
	{
		autoSize = true;
		_selectedRecipe = e.target.data;
		if ( null == _selectedRecipe )
				return;
		if ( _panelRecipe ) {
			_panelRecipe.remove();
			_panelRecipe = null;
		}
		//_recipeList.height = 10; // by resizing it here, the list can be properly be resize when the onResize method is called.
		_panelRecipe = new PanelRecipe( null, 300, 200, _selectedRecipe );
		_panelRecipe.borderStyle = BorderStyle.DOUBLE;
        _panelUpper.addElement( _panelRecipe );
	}
	
	private function onRecipe(e:CraftingEvent):void
	{
		_recipeList.addItem( e.recipe.name, e.recipe );
	}
	
	override protected function onRemoved( event:UIOEvent ):void
	{
		super.onRemoved( event );
		CraftingEvent.removeListener( ModelBaseEvent.RESULT, onRecipe );
		_recipeList = null;
		_selectedRecipe = null;
		_panelRecipe = null;
	}
}
}