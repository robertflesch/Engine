/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.inventory {

	import org.flashapi.swing.*
	import org.flashapi.swing.core.UIObject;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelRecipes extends VVContainer
	{
		// TODO need a more central location for these
        static public const MODEL_CAT_1:String = "GOD KNOWS 1";
        static public const MODEL_CAT_2:String = "GOD KNOWS 2";
        static public const MODEL_CAT_3:String = "GOD KNOWS 3";
        static public const MODEL_CAT_4:String = "GOD KNOWS 4";
		
		private var _barUpper:TabBar = new TabBar();
		// This hold the items to be displayed
		private var _itemContainer:Container;
		
		public function InventoryPanelRecipes() {
			super( this );
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			upperTabsAdd();
			addItemContainer();
		}
		
		private function upperTabsAdd():void {
			_barUpper.name = "upper";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _barUpper.addItem( LanguageManager.localizedStringGet( InventoryPanelModel.MODEL_CAT_ARCHITECTURE ), InventoryPanelModel.MODEL_CAT_ARCHITECTURE );
			_barUpper.addItem( LanguageManager.localizedStringGet( InventoryPanelModel.MODEL_CAT_CHARACTERS ), InventoryPanelModel.MODEL_CAT_CHARACTERS );
            _barUpper.addItem( LanguageManager.localizedStringGet( InventoryPanelModel.MODEL_CAT_PLANTS ), InventoryPanelModel.MODEL_CAT_PLANTS );
            _barUpper.addItem( LanguageManager.localizedStringGet( InventoryPanelModel.MODEL_CAT_FURNITURE ), InventoryPanelModel.MODEL_CAT_FURNITURE );
			_barUpper.setButtonsWidth( 128 );
			_barUpper.selectedIndex = 0;
            eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _barUpper );
		}

		private function addItemContainer():void {
			_itemContainer = new Container();
			_itemContainer.autoSize = true;
			_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
			addElement( _itemContainer );
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			displaySelectedCategory( e.target.value );	
		}
		
		// TODO I see problem here when langauge is different then what is in TypeInfo RSF - 11.16.14
		// That is if I use the target "Name"
		private function displaySelectedCategory( category:String ):void
		{	
		}
	}
}