
package com.voxelengine.GUI
{
	import com.voxelengine.worldmodel.animation.Animation;
	import com.voxelengine.worldmodel.inventory.InventoryObject;
	import com.voxelengine.worldmodel.models.Player;
	import flash.utils.Dictionary;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
	import org.flashapi.swing.event.ListEvent;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.containers.UIContainer;	
	import org.flashapi.swing.dnd.DnDOperation;

	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.GUI.CanvasHeirarchy;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelModels extends Box
	{
		private var _listModels:ListBox;
		private var _dictionarySource:Function;
		private var _parent:PanelModelAnimations;
		private var _selectedModel:VoxelModel;
		private var _buttonContainer:Container
		
		private const pbPadding:int = 5;
		
		private var _detailButton:Button
		
		//private var _dragOp:DnDOperation = new DnDOperation();
		
		
		public function PanelModels( $parent:PanelModelAnimations, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
		{
			super( $widthParam, $heightParam, BorderStyle.GROOVE );
			autoSize = true;
			backgroundColor = 0xCCCCCC;
			padding = pbPadding - 1;
			layout.orientation = LayoutOrientation.VERTICAL;
			_parent = $parent;
			
			//Log.out( "PanelModels - list box width: width: " + width + "  padding: " + pbPadding, Log.WARN );
			_listModels = new ListBox( width - pbPadding, $elementHeight, $heightParam );
			_listModels.dragEnabled = true;
			_listModels.draggable = true;

			//_listModels.dndData
			_listModels.addEventListener( ListEvent.LIST_CHANGED, selectModel );		
			//_listModels.eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
			//_listModels.eventCollector.addEvent( this, ListEvent.ITEM_PRESSED, doDrag);
			
			buttonsCreate();
			addElement( _listModels );
			
			//addListeners();
        }
		
		public function populateModels( $dictionarySource:Function ):void
		{
			_dictionarySource = $dictionarySource
			_listModels.removeAll();
			var countAdded:int;
			for each ( var vm:VoxelModel in _dictionarySource() )
			{
				if ( vm && !vm.instanceInfo.dynamicObject && !vm.dead )
				{
					if ( !Globals.g_debug ) {
						if ( vm is Player )
							continue;
					}
					var itemName:String = "" == vm.metadata.name ? "No Name(Player)" : vm.metadata.name;
					//Log.out( "PanelModels.populateModels - adding: " + itemName );
					
					_listModels.addItem( itemName, vm );
					countAdded++;
				}
			}
			if ( 0 == countAdded ) {
				_parent.childPanelRemove();
			}
		}

		//// FIXME This would be much better with drag and drop
		private function buttonsCreate():void {
			//Log.out( "PanelModels.buttonsCreate" );
			_buttonContainer = new Container( width, 10 );
			_buttonContainer.layout.orientation = LayoutOrientation.VERTICAL;
			_buttonContainer.padding = 2;
			_buttonContainer.height = 0;
			addElementAt( _buttonContainer, 0 );

			var addButton:Button = new Button( VoxelVerseGUI.resourceGet( "Model_Add", "+Add Model..." )  );
			addButton.addEventListener(UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowModelList(); } );
			addButton.width = width - 2 * pbPadding;
			_buttonContainer.addElement( addButton );
			_buttonContainer.height += addButton.height + pbPadding;
			
			var deleteButton:Button = new Button( VoxelVerseGUI.resourceGet( "Model_Delete", "+Delete Model") );
			deleteButton.addEventListener(UIMouseEvent.CLICK, deleteModelHandler );
			deleteButton.width = width - 2 * pbPadding;
			_buttonContainer.addElement( deleteButton );
			_buttonContainer.height += deleteButton.height + pbPadding;
			
			_detailButton = new Button( VoxelVerseGUI.resourceGet( "Model_Detail", "+Model Detail") );
			_detailButton.addEventListener( UIMouseEvent.CLICK, function (event:UIMouseEvent):void { if ( _selectedModel ) { new WindowModelDetail( _selectedModel ); } } );
			_detailButton.width = width - 2 * pbPadding;
			_detailButton.enabled = false;
			_buttonContainer.addElement( _detailButton );
			
			function deleteModelHandler(event:UIMouseEvent):void  {
				if ( _selectedModel )
				{
					// move this item to the players INVENTORY so that is it not "lost"
					// FIXME NEED TO DISPATCH EVENT HERE
					if ( Globals.player.inventory )
						Globals.player.inventory.add( InventoryObject.ITEM_MODEL, _selectedModel.instanceInfo.guid );
					Globals.markDead( _selectedModel.instanceInfo.guid );
					populateModels( _dictionarySource );
				}
				else
					noModelSelected();
			}
		}

		private function selectModel(event:ListEvent):void 
		{
			_selectedModel = event.target.data;
			if ( _selectedModel )
			{
				_detailButton.enabled = true;
				Globals.selectedModel = _selectedModel;
				_parent.childPanelAdd( _selectedModel );
				_parent.animationPanelAdd( _selectedModel );
			}
		}
		
		private function noModelSelected():void
		{
			(new Alert( VoxelVerseGUI.resourceGet( "No_Model_Selected", "No model selected" ) )).display();
		}
		
		public function topLevelGet():* {
			if ( _parent )
				return _parent.topLevelGet();
			return null;	
		}
		
		public function recalc( width:Number, height:Number ):void {
			_parent.recalc( width, height );
		}
		
		//private function rollOverHandler(e:UIMouseEvent):void 
		//{
			//Log.out( "PanelModels.UIMouseEvent.ROLL_OVER: " + e.toString() );
			//if ( null == _buttonContainer ) {
				//removeListeners();
				//buttonsCreate();
				//addListeners();
			//}
		//}
		//
		//private function rollOutHandler(e:UIMouseEvent):void 
		//{
			//Log.out( "PanelModels.UIMouseEvent.ROLL_OUT: " + e.toString() );
			//if ( null != _buttonContainer ) {
				//_buttonContainer.remove();
				//_buttonContainer = null;
				//removeListeners();
				//addListeners();
			//}
		//}
		//
		//private function addListeners():void {
			//Log.out( "PanelModels.addListeners" );
			//addEventListener( UIMouseEvent.ROLL_OVER, rollOverHandler );
			//addEventListener( UIMouseEvent.ROLL_OUT, rollOutHandler );
		//}
		//
		//private function removeListeners():void {
			//Log.out( "PanelModels.removeListeners" );
			//removeEventListener( UIMouseEvent.ROLL_OVER, rollOverHandler );
			//removeEventListener( UIMouseEvent.ROLL_OUT, rollOutHandler );
		//}
		//
		
	}
}