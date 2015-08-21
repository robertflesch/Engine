/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting 
{
import com.voxelengine.worldmodel.crafting.CraftingManager;
import com.voxelengine.worldmodel.crafting.items.CraftedItem;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.GUI.LanguageManager;

public class PanelRecipe extends PanelBase
{
	private var _panelForumla:PanelBase
	private var _panelButtons:PanelBase
	private var _panelMaterials:PanelMaterials;
	private var _panelBonuses:PanelBonuses;
	private var _panelPreview:PanelPreview;
	private var _recipeDesc:Label;
	
	private var _craftedItem:CraftedItem;
	
	public function PanelRecipe( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );
		borderStyle = BorderStyle.NONE;
		autoSize = true;
		padding = 0;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		var craftedClass:Class = CraftingManager.getClass( $recipe.className );
		if ( craftedClass )
			_craftedItem = new craftedClass( $recipe );
		
		_recipeDesc = new Label( "", 300 );
		addElement( _recipeDesc );
		if ( $recipe )
			_recipeDesc.text = $recipe.desc;
		
		_panelForumla = new PanelBase( this, $widthParam, $heightParam - 30 );
		_panelForumla.layout.orientation = LayoutOrientation.HORIZONTAL;
		addElement( _panelForumla );
		
		_panelBonuses = new PanelBonuses( this, $widthParam / 2, $height, $recipe );
		_panelBonuses.borderStyle = BorderStyle.NONE;

		_panelForumla.addElement( _panelBonuses );
		
		_panelMaterials = new PanelMaterials( this, $widthParam / 2, $height, $recipe );
		_panelForumla.addElement( _panelMaterials );
		
		_panelPreview = new PanelPreview( this, $widthParam / 2, $height, $recipe );
		_panelPreview.borderStyle = BorderStyle.NONE;
		_panelForumla.addElement( _panelPreview );
		
		_panelButtons = new PanelBase( this, $width, 30 );
		_panelButtons.layout.orientation = LayoutOrientation.HORIZONTAL;
		_panelButtons.borderStyle = BorderStyle.NONE;
		_panelButtons.padding = 5;
		addElement( _panelButtons );
		var craftButton:Button = new Button( LanguageManager.localizedStringGet( "Craft_Item" ) );
		eventCollector.addEvent( craftButton, UIMouseEvent.CLICK, craft );
		_panelButtons.addElement( craftButton );
		_panelButtons.addElement( new Label( "Drag Items from Inventory", 200 ) );
	}
	
	override public function remove():void {
		super.remove();
	}
	
	override public function close():void 
	{
		//super.onRemoved(e);
		_craftedItem.cancel();
		_craftedItem = null;
		_panelForumla.remove();
		_panelBonuses.remove();
		_panelMaterials.remove();
		_panelPreview.remove();
		_panelButtons.remove();
		
	}
	
	private function craft( e:UIMouseEvent ):void
	{
		
	}
	
	public function get craftedItem():CraftedItem 
	{
		return _craftedItem;
	}
}
}