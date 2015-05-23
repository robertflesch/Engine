/*==============================================================================
  Copyright 2011-2015 Robert Flesch
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
	import org.flashapi.swing.dnd.*;
	import org.flashapi.swing.button.RadioButtonGroup;
	import org.flashapi.swing.databinding.DataProvider;
	import org.flashapi.swing.plaf.spas.SpasUI;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	import com.voxelengine.events.*;
	
	public class WindowInventoryNew extends VVPopup
	{
        static public const ALL_ITEMS:String = "all_items";
        static public const INVENTORY_OWNED:String = "backpack";
        static public const INVENTORY_STORE:String = "store";
		
		// TODO need a more central location for these
        static public const INVENTORY_CAT_VOXELS:String = "Voxels";
        static public const INVENTORY_CAT_MODELS:String = "Models";
        static public const INVENTORY_CAT_REGIONS:String = "Regions";
		
        private var _ownedVsStore:TabBar;
		private var _panelContainer:Container;
		private var _rbGroup:RadioButtonGroup;
		private var _underline:Box
		
		static public function makeStartingTabString( $parentTab:String, ...args ):String {
			var result:String = $parentTab + ";";
			for ( var i:uint = 0; i < args.length; i++ ) {
				result += args[i] + ";";
			}
			return result;
		}
		
		static public var _s_hackShowChildren:Boolean;
		static public var _s_hackSupportClick:Boolean;
		
		public function WindowInventoryNew( $startingTab:String )
		{
			super( LanguageManager.localizedStringGet( ALL_ITEMS ));
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			//ownedVsStoreRB();
			ownedVsStoreTabsHorizontal( $startingTab );
			
			var count:int = width / 64;
			width = count * 64;
			
			display();
			
			move( Globals.g_renderer.width / 2 - width / 2, Globals.g_renderer.height / 2 - height / 2 );
			addEventListener( UIOEvent.RESIZED, onResized );
		}
		
		public function onResized(e:UIOEvent):void 
		{
			_ownedVsStore.setButtonsWidth( width / 2, 36 );
		}
		
		public function onResizedFromChild(e:UIOEvent):void 
		{
			_ownedVsStore.setButtonsWidth( width / 2, 36 );
		}

		private function ownedVsStoreTabsHorizontal( $tabTokens:String ):void {
			var index:int = $tabTokens.indexOf( ";" );
			var startingTabName:String;
			if ( -1 < index ) {
				startingTabName = $tabTokens.substr( 0 , index );
				$tabTokens = $tabTokens.substr( index + 1, $tabTokens.length );
			}
			_ownedVsStore = new TabBar();
			_ownedVsStore.orientation = ButtonBarOrientation.HORIZONTAL;
			_ownedVsStore.name = "ownedVsStore";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_OWNED ), INVENTORY_OWNED );
			_ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_STORE ), INVENTORY_STORE );
			_ownedVsStore.setButtonsWidth( 256, 36 );
			if ( startingTabName == INVENTORY_OWNED )
				_ownedVsStore.selectedIndex = 0;
			else
				_ownedVsStore.selectedIndex = 1;
			//_ownedVsStore.itemsCollection
            eventCollector.addEvent( _ownedVsStore, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _ownedVsStore );
			
			_underline = new Box( width, 5 );
			_underline.backgroundColor = SpasUI.DEFAULT_COLOR
			addGraphicElements( _underline );			
			
			displaySelectedContainer( startingTabName, $tabTokens );
		}
		
		override protected function onRemoved( event:UIOEvent ):void {
			
			removeEventListener( UIOEvent.RESIZED, onResized );
			_ownedVsStore.remove();
			_ownedVsStore = null;

			if ( _panelContainer ) {
				_panelContainer.remove();
				_panelContainer = null;
			}
			
			super.onRemoved( event );
			_s_hackShowChildren = false;
			_s_hackSupportClick = false;
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			displaySelectedContainer( e.target.data as String, "" );	
		}
		
		private function displaySelectedContainer( $category:String, $tabTokens:String ):void
		{	
			if ( _panelContainer ) {
				removeElement( _panelContainer );
				_panelContainer.remove();
			}
				
			_panelContainer = new InventoryPanelOverview( this, $category, $tabTokens );
			addElement( _panelContainer );
		}
	}
}