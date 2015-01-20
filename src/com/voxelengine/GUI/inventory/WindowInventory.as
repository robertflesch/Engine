package com.voxelengine.GUI.inventory {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*
	import org.flashapi.swing.core.UIObject;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.dnd.*;
	import org.flashapi.swing.layout.AbsoluteLayout;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.TypeInfo;
	import com.voxelengine.GUI.crafting.*;
	import com.voxelengine.events.CraftingItemEvent;
	import com.voxelengine.GUI.*;
	
	public class WindowInventory extends VVPopup
	{
		private var _dragOp:DnDOperation = new DnDOperation();
        private var _barUpper:TabBar = new TabBar();
		private var _barLower:TabBar = new TabBar();
		private var _itemContainer:Container = new Container( 64, 64);
		
		public function WindowInventory()
		{
			super( LanguageManager.localizedStringGet( "Inventory" ));
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			upperTabsAdd();
			addItemContainer();
			lowerTabsAdd();
			
			var count:int = width / 64;
			width = count * 64;
			
			displaySelectedCategory( "all" );
			
            eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
			eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
			
			display();
			
			
			move( Globals.g_renderer.width / 2 - width / 2, Globals.g_renderer.height / 2 - height / 2 );
		}
		
		private function upperTabsAdd():void {
			_barUpper.name = "upper";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _barUpper.addItem( LanguageManager.localizedStringGet( "Earth" ) );
			_barUpper.addItem( LanguageManager.localizedStringGet( "Liquid" ) );
            _barUpper.addItem( LanguageManager.localizedStringGet( "Plant" ) );
            _barUpper.addItem( LanguageManager.localizedStringGet( "Metal" ) );
            _barUpper.addItem( LanguageManager.localizedStringGet( "Air" ) );
            var li:ListItem = _barUpper.addItem( LanguageManager.localizedStringGet( "All" ) );
			_barUpper.setButtonsWidth( 128 );
			_barUpper.selectedIndex = li.index;
            eventCollector.addEvent( _barUpper, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( _barUpper );
		}

		private function addItemContainer():void {
			addElement( _itemContainer );
			_itemContainer.autoSize = true;
			_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		}
		private function lowerTabsAdd():void {
			_barLower.name = "lower";
			// TODO I should really iterate thru the types and collect the categories - RSF
            _barLower.addItem( LanguageManager.localizedStringGet( "Dragon" ) );
            _barLower.addItem( LanguageManager.localizedStringGet( "Util" ) );
            _barLower.addItem( LanguageManager.localizedStringGet( "Gem" ) );
            _barLower.addItem( LanguageManager.localizedStringGet( "Avatar" ) );
            _barLower.addItem( LanguageManager.localizedStringGet( "Light" ) );
            _barLower.addItem( LanguageManager.localizedStringGet( "Crafting" ) );
			_barLower.setButtonsWidth( 128 );
            eventCollector.addEvent( _barLower, ListEvent.ITEM_CLICKED, selectCategory );
			addGraphicElements( _barLower );
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			//Log.out( "WindowInventory.selectCategory" );
			while ( 1 <= _itemContainer.numElements )
				_itemContainer.removeElementAt( 0 );
			
			if ( e.target.name == "lower" )
				_barUpper.selectedIndex = -1;
			else
				_barLower.selectedIndex = -1;
				
			displaySelectedCategory( e.target.value );	
		}
		
		// TODO I see problem here when langauge is different then what is in TypeInfo RSF - 11.16.14
		private function displaySelectedCategory( category:String ):void
		{	
			var count:int = 0;
			var pc:Container = new Container( width, 64 );
			pc.layout = new AbsoluteLayout();

			var countMax:int = width / 64;
			var box:BoxInventory;
			for each (var item:TypeInfo in Globals.Info )
			{
				if ( item.placeable && (item.category.toUpperCase() == category.toUpperCase() || "ALL" == String(category).toUpperCase() ) )
				{
//					if ( "crafting" == category.toLowerCase() )
//						continue;
					// Add the filled bar to the container and create a new container
					if ( countMax == count )
					{
						_itemContainer.addElement( pc );
						pc = new Container( width, 64 );
						pc.layout = new AbsoluteLayout();
						count = 0;		
					}
					box = new BoxInventory(64, 64, BorderStyle.NONE, item );
					box.x = count * 64;
					pc.addElement( box );
					eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);

					count++
				}
			}
			_itemContainer.addElement( pc );
		}
		
		private function dropMaterial(e:DnDEvent):void 
		{
			if ( e.dragOperation.initiator.data is TypeInfo )
			{
				e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
				e.dropTarget.data = e.dragOperation.initiator.data;
				
				if ( e.dropTarget.target is PanelMaterials ) {
					Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				}
				else if ( e.dropTarget.target is PanelBonuses ) {
					Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
					e.dropTarget.backgroundTextureManager.resize( 32, 32 );
				}
			}
		}
		
		private function doDrag(e:UIMouseEvent):void 
		{
			_dragOp.initiator = e.target as UIObject;
			_dragOp.dragImage = e.target as DisplayObject;
			// this adds a drop format, which is checked again what the target is expecting
			_dragOp.resetDropFormat();
			var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
			_dragOp.addDropFormat( dndFmt );
			
			UIManager.dragManager.startDragDrop(_dragOp);
		}			
		
	}
}