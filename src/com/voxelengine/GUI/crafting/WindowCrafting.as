
package com.voxelengine.GUI.crafting {
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.worldmodel.crafting.CraftingManager;
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
		super( VoxelVerseGUI.localizedStringGet( "Crafting", "Crafting" ) );
		width = 150;
		height = 300;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		addEventListener( UIOEvent.RESIZED, onResized );
		
		_recipeList = new ListBox( width, 15, PANEL_HEIGHT );
		_recipeList.addEventListener( ListEvent.LIST_CHANGED, selectRecipe );		
		addElement( _recipeList );
		
		if ( null == Globals.g_craftingManager ) {
			Globals.g_craftingManager = new CraftingManager();
		}
		
		display();
		
		addEventListener(UIOEvent.REMOVED, onRemoved );
		Globals.g_app.addEventListener( CraftingEvent.RECIPE_LOADED, onRecipeLoaded );
		Globals.g_app.dispatchEvent( new CraftingEvent( CraftingEvent.RECIPE_LOAD_PUBLIC, null, null ) );
	}
	
	private function onResized(e:UIOEvent):void 
	{
		_recipeList.height = height;
	}
	
	private function selectRecipe(e:ListEvent):void 
	{
		autoSize = true;
		_selectedRecipe = e.target.data;
		if ( _panelRecipe ) {
			_panelRecipe.remove();
			_panelRecipe = null;
		}
		_recipeList.height = 10; // by resizing it here, the list can be properly be resize when the onResize method is called.
		_panelRecipe = new PanelRecipe( null, 200, 200, _selectedRecipe );
		_panelRecipe.borderStyle = BorderStyle.DOUBLE;
		addElement( _panelRecipe );
	}
	
	private function onRecipeLoaded(e:CraftingEvent):void 
	{
		_recipeList.addItem( e.name, e.recipe );
	}
	
	override protected function onRemoved( event:UIOEvent ):void
	{
		super.onRemoved( event );
		Globals.g_app.removeEventListener( CraftingEvent.RECIPE_LOADED, onRecipeLoaded );
		_recipeList = null;
		_selectedRecipe = null;
		_panelRecipe = null;
	}
}
}