
package com.voxelengine.GUI.crafting 
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.PanelBase;
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.worldmodel.crafting.Recipe;

public class PanelRecipe extends PanelBase
{
	private var _panelForumla:PanelBase
	private var _panelButtons:PanelBase
	private var _panelMaterials:PanelMaterials;
	private var _panelBonuses:PanelBonuses;
	private var _panelPreview:PanelPreview;
	private var _recipeDesc:Label;
	
	public function PanelRecipe( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );
		borderStyle = BorderStyle.NONE;
		autoSize = true;
		padding = 0;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		_recipeDesc = new Label( "Desc of Recipe", 300 );
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
		_panelButtons.borderStyle = BorderStyle.NONE;
		_panelButtons.padding = 5;
		addElement( _panelButtons );
		var craftButton:Button = new Button( VoxelVerseGUI.localizedStringGet( "Craft_Item", "Craft Item" ) );
		eventCollector.addEvent( craftButton, UIMouseEvent.CLICK, craft );

		_panelButtons.addElement( craftButton );
	}
	
	private function craft( e:UIMouseEvent ):void
	{
		
	}
}
}