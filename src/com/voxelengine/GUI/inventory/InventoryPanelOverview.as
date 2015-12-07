/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {

	import org.flashapi.swing.*
	import org.flashapi.swing.containers.UIContainer;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.plaf.spas.SpasUI;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelOverview extends VVContainer
	{
		private var _barUpper:TabBar;
		// This hold the items to be displayed
		private var _panelContainer:Container;
		private var _sourceType:String;
		private var _underline:Box;
		private var _parentWindow:UIContainer;
		
		public function InventoryPanelOverview( $windowInventoryNew:UIContainer, $source:String, $tabTokens:String ) {
			_parentWindow = $windowInventoryNew;
			super( null );
			_sourceType = $source;
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			var index:int = $tabTokens.indexOf( ";" );
			var startingTabName:String;
			if ( -1 < index ) {
				startingTabName = $tabTokens.substr( 0 , index );
				$tabTokens = $tabTokens.substr( index + 1, $tabTokens.length );
			}

			upperTabsAdd( startingTabName );
			//addItemContainer();
			addEventListener( UIOEvent.RESIZED, onResized );
			
			
			displaySelectedContainer( startingTabName, $tabTokens );
		}
		
		override protected function onResized(e:UIOEvent):void 
		{
			_barUpper.setButtonsWidth( width / _barUpper.length, 36 );
			(_parentWindow as WindowInventoryNew).onResizedFromChild( e );
			//_underline.width = width;
		}
		
		override protected function onRemoved( event:UIOEvent ):void {
			
			removeEventListener( UIOEvent.RESIZED, onResized );
			
			_barUpper.remove();
			_barUpper = null;

			if ( _panelContainer ) {
				_panelContainer.remove();
				_panelContainer = null;
			}
			
			super.onRemoved( event );
		}
		
		private static var _s_lastSelectedIndex:int
		private function upperTabsAdd( $startingTabName:String ):void {
			_barUpper = new TabBar();
			_barUpper.name = "upper";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_VOXELS ), WindowInventoryNew.INVENTORY_CAT_VOXELS );
			_barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_MODELS ), WindowInventoryNew.INVENTORY_CAT_MODELS );
            _barUpper.addItem( LanguageManager.localizedStringGet( WindowInventoryNew.INVENTORY_CAT_REGIONS ), WindowInventoryNew.INVENTORY_CAT_REGIONS );
//            _barUpper.addItem( LanguageManager.localizedStringGet( "Animations" ) );
//            _barUpper.addItem( LanguageManager.localizedStringGet( "Recipes" ) );
            //var li:ListItem = _barUpper.addItem( LanguageManager.localizedStringGet( "All" ) );
			_barUpper.setButtonsWidth( 192 );
			_barUpper.height = 40;
			if ( WindowInventoryNew.INVENTORY_CAT_VOXELS == $startingTabName )
				_s_lastSelectedIndex = _barUpper.selectedIndex = 0;
			else if ( WindowInventoryNew.INVENTORY_CAT_MODELS == $startingTabName )
				_s_lastSelectedIndex = _barUpper.selectedIndex = 1;
			else if ( WindowInventoryNew.INVENTORY_CAT_REGIONS == $startingTabName )
				_s_lastSelectedIndex = _barUpper.selectedIndex = 2;
			else WindowInventoryNew.INVENTORY_CAT_LAST
				_barUpper.selectedIndex = _s_lastSelectedIndex

			eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _barUpper );
			_underline = new Box( width, 5);
			_underline.backgroundColor = SpasUI.DEFAULT_COLOR
            addGraphicElements( _underline );			
			
		}

		private function selectCategory(e:ListEvent):void 
		{			
			_s_lastCategory = e.target.data as String
			displaySelectedContainer( _s_lastCategory, "" );	
		}
		
		private static var _s_lastCategory:String
		private function displaySelectedContainer( $category:String, $tabTokens:String ):void
		{	
			if ( _panelContainer ) {
				removeElement( _panelContainer );
				_panelContainer.remove();
			}
			
			if ( WindowInventoryNew.INVENTORY_CAT_LAST == $category ) {
				// does last have a value? if not give it voxels
				if ( null == _s_lastCategory || 0 == _s_lastCategory.length || _s_lastCategory)
					_s_lastCategory = WindowInventoryNew.INVENTORY_CAT_VOXELS
				$category = _s_lastCategory
			}
			if ( WindowInventoryNew.INVENTORY_CAT_VOXELS == $category )
				_panelContainer = new InventoryPanelVoxel( this );
			else if ( WindowInventoryNew.INVENTORY_CAT_MODELS == $category )	
				_panelContainer = new InventoryPanelModel( this );
			else if ( WindowInventoryNew.INVENTORY_CAT_REGIONS == $category )	
				_panelContainer = new InventoryPanelRegions( this );
				
			addElement( _panelContainer );
		}
	}
}