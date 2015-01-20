/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

	import org.flashapi.swing.*
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelRegions extends VVContainer
	{
		// TODO need a more central location for these
        static public const REGION_CAT_PRIVATE:String = "Personal";
        static public const REGION_CAT_GROUP:String = "Group";
        static public const REGION_CAT_MANAGE:String = "Manage";
		
		private var _barUpper:TabBar;
		// This hold the items to be displayed
		private var _itemContainer:Container;
		
		public function InventoryPanelRegions( $parent:VVContainer ) {
			super( $parent );
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			upperTabsAdd();
			addItemContainer();
		}
		
		private function upperTabsAdd():void {
			_barUpper = new TabBar();
			_barUpper.orientation = ButtonBarOrientation.VERTICAL;
			_barUpper.name = "upper";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _barUpper.addItem( LanguageManager.localizedStringGet( REGION_CAT_PRIVATE ), REGION_CAT_PRIVATE );
			_barUpper.addItem( LanguageManager.localizedStringGet( REGION_CAT_GROUP ), REGION_CAT_GROUP );
            _barUpper.addItem( LanguageManager.localizedStringGet( REGION_CAT_MANAGE ), REGION_CAT_MANAGE );
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