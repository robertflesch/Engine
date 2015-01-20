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
        static public const ALL_ITEMS:String = "All items";
        static public const INVENTORY_OWNED:String = "Backpack";
        static public const INVENTORY_STORE:String = "Store";
		
        private var _ownedVsStore:TabBar;
		private var _panelContainer:Container;
		private var _rbGroup:RadioButtonGroup;
		private var _underline:Box
		
		public function WindowInventoryNew()
		{
			super( LanguageManager.localizedStringGet( ALL_ITEMS ));
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			//ownedVsStoreRB();
			ownedVsStoreTabsHorizontal();
			
			var count:int = width / 64;
			width = count * 64;
			
			display();
			
			move( Globals.g_renderer.width / 2 - width / 2, Globals.g_renderer.height / 2 - height / 2 );
			addEventListener( UIOEvent.RESIZED, onResized );
		}
		
		public function onResized(e:UIOEvent):void 
		{
			_ownedVsStore.setButtonsWidth( width / 2, 36 );
			//_underline.width = width;
		}
		
		public function onResizedFromChild(e:UIOEvent):void 
		{
			//_ownedVsStore.setButtonsWidth( width / 2, 36 );
			//_underline.width = width;
		}

		private function ownedVsStoreRB():void {
			var rbContainer:Container = new Container(width, 20);
			rbContainer.layout.orientation = LayoutOrientation.HORIZONTAL;
			addElement( rbContainer );
			_rbGroup = new RadioButtonGroup( rbContainer );
			var radioButtons:DataProvider = new DataProvider();
            radioButtons.addAll( { label:LanguageManager.localizedStringGet( INVENTORY_OWNED ), data:INVENTORY_OWNED }
			                   , { label:LanguageManager.localizedStringGet( INVENTORY_STORE ), data:INVENTORY_STORE } );
			eventCollector.addEvent( _rbGroup, ButtonsGroupEvent.GROUP_CHANGED
		                           , function (event:ButtonsGroupEvent):void {  displaySelectedContainer( event.target.data ); } );
			_rbGroup.dataProvider = radioButtons;
			_rbGroup.index = 0;
			addGraphicElements( new Box( 10, height) );			
		}

		private function ownedVsStoreTabsHorizontal():void {
			_ownedVsStore = new TabBar();
			_ownedVsStore.orientation = ButtonBarOrientation.HORIZONTAL;
			_ownedVsStore.name = "ownedVsStore";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_OWNED ), INVENTORY_OWNED );
			_ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_STORE ), INVENTORY_STORE );
			_ownedVsStore.setButtonsWidth( 256, 36 );
			_ownedVsStore.selectedIndex = 0;
			//_ownedVsStore.itemsCollection
            eventCollector.addEvent( _ownedVsStore, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _ownedVsStore );
			
			_underline = new Box( width, 5 );
			_underline.backgroundColor = SpasUI.DEFAULT_COLOR
			addGraphicElements( _underline );			
			
			displaySelectedContainer( INVENTORY_OWNED );
		}
		
		private function ownedVsStoreTabsVertical():void {
			_ownedVsStore = new TabBar();
			_ownedVsStore.orientation = ButtonBarOrientation.VERTICAL;
			_ownedVsStore.name = "ownedVsStore";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_OWNED ), INVENTORY_OWNED );
			_ownedVsStore.addItem( LanguageManager.localizedStringGet( INVENTORY_STORE ), INVENTORY_STORE );
			_ownedVsStore.setButtonsWidth( 32 );
			_ownedVsStore.selectedIndex = 0;
            eventCollector.addEvent( _ownedVsStore, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _ownedVsStore );
			addGraphicElements( new Box( 5, height) );			
			displaySelectedContainer( INVENTORY_OWNED );
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
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			displaySelectedContainer( e.target.data as String );	
		}
		
		private function displaySelectedContainer( $category:String ):void
		{	
			if ( _panelContainer ) {
				removeElement( _panelContainer );
				_panelContainer.remove();
			}
				
			_panelContainer = new InventoryPanelOverview( this, $category );
			addElement( _panelContainer );
		}
	}
}