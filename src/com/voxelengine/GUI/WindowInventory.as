package com.voxelengine.GUI
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
//	import flash.display.BlendMode;
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
	
	public class WindowInventory extends VVPopup
	{
		private var _dragOp:DnDOperation = new DnDOperation();
        private var bar:TabBar = new TabBar();
		private var barLower:TabBar = new TabBar();
		private var itemContainer:Container = new Container( 64, 64);
		
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
			// TODO I should really iterate thru the types and collect the categories - RSF
            bar.addItem( LanguageManager.localizedStringGet( "Earth" ) );
			bar.addItem( LanguageManager.localizedStringGet( "Liquid" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Plant" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Metal" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Air" ) );
            var li:ListItem = bar.addItem( LanguageManager.localizedStringGet( "All" ) );
			bar.setButtonsWidth( 128 );
			bar.selectedIndex = li.index;
            eventCollector.addEvent( bar, ListEvent.ITEM_CLICKED, selectCategory );
            addGraphicElements( bar );
		}

		private function addItemContainer():void {
			addElement( itemContainer );
			itemContainer.autoSize = true;
			itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		}
		private function lowerTabsAdd():void {
			// TODO I should really iterate thru the types and collect the categories - RSF
            barLower.addItem( LanguageManager.localizedStringGet( "Dragon" ) );
            barLower.addItem( LanguageManager.localizedStringGet( "Util" ) );
            barLower.addItem( LanguageManager.localizedStringGet( "Gem" ) );
            barLower.addItem( LanguageManager.localizedStringGet( "Avatar" ) );
            barLower.addItem( LanguageManager.localizedStringGet( "Light" ) );
            barLower.addItem( LanguageManager.localizedStringGet( "Crafting" ) );
			barLower.setButtonsWidth( 128 );
            eventCollector.addEvent( barLower, ListEvent.ITEM_CLICKED, selectCategory );
			addGraphicElements( barLower );
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			//Log.out( "WindowInventory.selectCategory" );
			while ( 1 <= itemContainer.numElements )
			{
				itemContainer.removeElementAt( 0 );
			}
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
				if ( "BONUSES" == category.toUpperCase() ) {
					if ( Globals.MODIFIER_DAMAGE == item.category.toUpperCase()
					  || Globals.MODIFIER_DURABILITY == item.category.toUpperCase()
					  || Globals.MODIFIER_LUCK == item.category.toUpperCase()
					  || Globals.MODIFIER_SPEED == item.category.toUpperCase() ) 
					  {
							if ( countMax == count )
							{
								itemContainer.addElement( pc );
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
				else if ( item.placeable && (item.category.toUpperCase() == category.toUpperCase() || "ALL" == String(category).toUpperCase() ) )
				{
					if ( countMax == count )
					{
						itemContainer.addElement( pc );
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
			itemContainer.addElement( pc );
		}
		
		private function dropMaterial(e:DnDEvent):void 
		{
			if ( e.dragOperation.initiator.data is TypeInfo )
			{
				e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
				e.dropTarget.data = e.dragOperation.initiator.data;
				
				if ( e.dropTarget.target is PanelMaterials ) {
					Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.DROPPED_MATERIAL, e.dragOperation.initiator.data as TypeInfo ) );	
				}
				else if ( e.dropTarget.target is PanelBonuses ) {
					Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.DROPPED_BONUS, e.dragOperation.initiator.data as TypeInfo ) );	
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