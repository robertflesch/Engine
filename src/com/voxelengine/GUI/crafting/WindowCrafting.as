/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting {
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.server.Network;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.worldmodel.crafting.RecipeCache;
import com.voxelengine.worldmodel.crafting.Recipe;


public class WindowCrafting extends VVPopup
{
	private const PANEL_WIDTH:int = 200;
	private const PANEL_HEIGHT:int = 300;
	private const PANEL_BUTTON_HEIGHT:int = 200;
	
	private var _recipeList:ListBox;
	private var _selectedRecipe:Recipe;
	private var _panelRecipe:PanelRecipe;
	
	public function WindowCrafting()
	{
		super( LanguageManager.localizedStringGet( "Crafting" ) );
		width = 150;
		height = 300;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		addEventListener( UIOEvent.RESIZED, onResized );
		
		_recipeList = new ListBox( width, 15, PANEL_HEIGHT );
		_recipeList.addEventListener( ListEvent.LIST_CHANGED, selectRecipe );		
		addElement( _recipeList );
		
		// This makes sure the crafting manager is running
		display();
		
		addEventListener(UIOEvent.REMOVED, onRemoved );
		CraftingEvent.addListener( ModelBaseEvent.RESULT_RANGE, onRecipe );
        CraftingEvent.addListener( ModelBaseEvent.RESULT, onRecipe );
		CraftingEvent.create( ModelBaseEvent.REQUEST_TYPE, Network.userId, null );
	}
	
	private function onResized(e:UIOEvent):void 
	{
		_recipeList.height = height;
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
		_recipeList.height = 10; // by resizing it here, the list can be properly be resize when the onResize method is called.
		_panelRecipe = new PanelRecipe( null, 200, 200, _selectedRecipe );
		_panelRecipe.borderStyle = BorderStyle.DOUBLE;
		addElement( _panelRecipe );
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