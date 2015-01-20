package com.voxelengine.GUI.inventory {

	import org.flashapi.swing.*
	import org.flashapi.swing.core.UIObject;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelModel extends VVContainer
	{
		// TODO need a more central location for these
        static public const MODEL_CAT_ARCHITECTURE:String = "Architecture";
        static public const MODEL_CAT_CHARACTERS:String = "Characters";
        static public const MODEL_CAT_PLANTS:String = "Plants";
        static public const MODEL_CAT_FURNITURE:String = "Furniture";
		
		private var _barUpper:TabBar
		// This hold the items to be displayed
		private var _itemContainer:Container;
		
		public function InventoryPanelModel( $parent:VVContainer ) {
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
            _barUpper.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ARCHITECTURE ), MODEL_CAT_ARCHITECTURE );
			_barUpper.addItem( LanguageManager.localizedStringGet( MODEL_CAT_CHARACTERS ), MODEL_CAT_CHARACTERS );
            _barUpper.addItem( LanguageManager.localizedStringGet( MODEL_CAT_PLANTS ), MODEL_CAT_PLANTS );
            _barUpper.addItem( LanguageManager.localizedStringGet( MODEL_CAT_FURNITURE ), MODEL_CAT_FURNITURE );
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