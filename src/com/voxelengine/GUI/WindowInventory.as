package com.voxelengine.GUI
{
	import flash.display.Bitmap;
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
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.TypeInfo;
	import com.voxelengine.GUI.crafting.*;
	
	public class WindowInventory extends VVPopup
	{
		private var _dragOp:DnDOperation = new DnDOperation();
		
		public function WindowInventory()
		{
			super( LanguageManager.localizedStringGet( "Inventory" ));
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
            var bar:TabBar = new TabBar();
			// TODO I should really iterate thru that types and collect the categories - RSF
            bar.addItem( LanguageManager.localizedStringGet( "Earth" ) );
			bar.addItem( LanguageManager.localizedStringGet( "Liquid" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Plant" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Metal" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Air" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Dragon" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Util" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Gem" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Avatar" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Light" ) );
            bar.addItem( LanguageManager.localizedStringGet( "Bonuses" ) );
            var li:ListItem = bar.addItem( LanguageManager.localizedStringGet( "All" ) );
			bar.setButtonsWidth( 64 );
			bar.selectedIndex = li.index;
            
            addGraphicElements( bar );
            
            eventCollector.addEvent( bar, ListEvent.ITEM_CLICKED, selectCategory );
            eventCollector.addEvent( bar, ListEvent.ITEM_PRESSED, pressCategory );
            eventCollector.addEvent( this, UIMouseEvent.CLICK, windowClick );
            eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
            eventCollector.addEvent( this, UIMouseEvent.PRESS, pressWindow );
			eventCollector.addEvent(_dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
			
			display();
			
			displaySelectedCategory( "all" );
			
			move( Globals.g_renderer.width / 2 - width / 2, Globals.g_renderer.height / 2 - height / 2 );
		}

		import org.flashapi.swing.managers.TextureManager;
		static private var _s_backGroundTextureManager:TextureManager
		private function dropMaterial(e:DnDEvent):void 
		{
			//Log.out( "WindowInventory.dropMaterial" );
			
			if ( e.dragOperation.initiator.data is TypeInfo )
			{
				var dropOK:Boolean;
				var category:String = e.dragOperation.initiator.data.category.toUpperCase();
				if ( e.dropTarget.target is QuickInventory )
					dropOK = true;
				else if ( e.dropTarget.target is PanelMaterials ) {
					
					if ( e.dropTarget is BoxWood && Globals.CATEGORY_PLANT == category )
						dropOK = true;
					else if ( e.dropTarget is BoxMetal && Globals.CATEGORY_METAL == category )
						dropOK = true;
					else if ( e.dropTarget is BoxLeather && Globals.CATEGORY_LEATHER == category )
						dropOK = true;
				}
				else if ( e.dropTarget.target is PanelBonuses ) {
					
					if ( e.dropTarget is BoxDamage && Globals.MODIFIER_DAMAGE == category )
						dropOK = true;
					else if ( e.dropTarget is BoxSpeed && Globals.MODIFIER_SPEED == category )
						dropOK = true;
					else if ( e.dropTarget is BoxDurability && Globals.MODIFIER_DURABILITY == category )
						dropOK = true;
					else if ( e.dropTarget is BoxLuck && Globals.MODIFIER_LUCK == category )
						dropOK = true;
				}
				
				if ( dropOK ) {
					e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
					e.dropTarget.data = e.dragOperation.initiator.data;
					if ( e.dropTarget.target is PanelBonuses )
						e.dropTarget.backgroundTextureManager.resize( 32, 32 );
				}
			}
		}
		
		private function doDrag(e:UIMouseEvent):void 
		{
			//Log.out( "WindowInventory.doDrag" );
			_dragOp.initiator = e.target as UIObject;
			UIManager.dragManager.startDragDrop(_dragOp);
		}			
		
		private function pressWindow(e:UIMouseEvent):void
		{
			//Log.out( "WindowInventory.pressWindow" );
		}
		private function windowClick(e:UIMouseEvent):void
		{
			//Log.out( "WindowInventory.windowClick" );
		}
		private function pressCategory(e:UIMouseEvent):void
		{
			//Log.out( "WindowInventory.pressCategory" );
		}
		
		private function selectCategory(e:ListEvent):void 
		{			
			//Log.out( "WindowInventory.selectCategory" );
			while ( 1 < numElements )
			{
				removeElementAt( 1 );
			}
			displaySelectedCategory( e.target.value );	
		}
		
		// TODO I see problem here when langauge is different then what is in TypeInfo RSF - 11.16.14
		private function displaySelectedCategory( category:String ):void
		{	
			var count:int = 0;
			var pc:Container = new Container( width, 64 );
			//pc.autoSize = false;
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
								addElement( pc );
								pc = new Container( width, 64 );
								count = 0;		
							}
							box = new BoxInventory(64, 64, BorderStyle.INSET, item );
							pc.addElement( box );
							eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
							count++
					  }
				}
				else if ( item.placeable && (item.category.toUpperCase() == category.toUpperCase() || "ALL" == String(category).toUpperCase() ) )
				{
					if ( countMax == count )
					{
						addElement( pc );
						pc = new Container( width, 64 );
						count = 0;		
					}
					box = new BoxInventory(64, 64, BorderStyle.INSET, item );
					pc.addElement( box );
					eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
					count++
				}
			}
			addElement( pc );
		}
	}
}