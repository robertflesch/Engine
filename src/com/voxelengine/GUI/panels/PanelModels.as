/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.worldmodel.models.ModelCache;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.event.ListEvent;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.dnd.DnDOperation;


import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.UIRegionModelEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.inventory.WindowInventoryNew;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import com.voxelengine.worldmodel.inventory.Inventory;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModels extends PanelBase
{
	private var _parentModel:VoxelModel;
	private var _listModels:ListBox;
	private var _dictionarySource:Function;
	private var _selectedModel:VoxelModel;
	private var _buttonContainer:Container
	
	private var _detailButton:Button
	private var _deleteButton:Button
	
	//private var _dragOp:DnDOperation = new DnDOperation();
	
	
	public function PanelModels( $parent:PanelModelAnimations, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
	{
		super( $parent, $widthParam, $heightParam );
		_parent = $parent;
		
		//Log.out( "PanelModels - list box width: width: " + width + "  padding: " + pbPadding, Log.WARN );
		_listModels = new ListBox( width - pbPadding, $elementHeight, $heightParam );
		_listModels.dragEnabled = true;
		_listModels.draggable = true;

		_listModels.eventCollector.addEvent( _listModels, ListEvent.ITEM_PRESSED, selectModel );		
		
		buttonsCreate();
		addElement( _listModels );
		
		// ALL DRAG AND DROP methods, which are not working
		//_listModels.dndData
		//_listModels.eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		//_listModels.eventCollector.addEvent( this, ListEvent.ITEM_PRESSED, doDrag);
		//addListeners();
	}
	
	override public function close():void {
		super.close();
		_listModels.removeEventListener( ListEvent.LIST_CHANGED, selectModel );		
		
		_parentModel = null;
		_dictionarySource = null;
		_selectedModel = null;
	}
	
	public function populateModels( $source:Function, $parentModel:VoxelModel ):int
	{
		_dictionarySource = $source;
		_parentModel = $parentModel;
		_selectedModel = null;
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
				var itemName:String = "";
				if ( vm.metadata.name )
					itemName = vm.metadata.name;
				else	
					itemName = vm.modelInfo.fileName;
				//Log.out( "PanelModels.populateModels - adding: " + itemName );
				
				_listModels.addItem( itemName, vm );
				countAdded++;
			}
		}
		return countAdded;
	}

	//// FIXME This would be much better with drag and drop
	// meaning removing the buttons completely
	private function buttonsCreate():void {
		
		const btnWidth:int = width - 10;
		//Log.out( "PanelModels.buttonsCreate" );
		_buttonContainer = new Container( width, 10 );
		//_buttonContainer.layout.orientation = LayoutOrientation.VERTICAL;
		_buttonContainer.layout = new AbsoluteLayout();
		_buttonContainer.padding = 0;
		_buttonContainer.height = 0;
		addElementAt( _buttonContainer, 0 );

		var addButton:Button = new Button( LanguageManager.localizedStringGet( "Model_Add" ) + ".."  );
		//addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowModelList(); } );
		addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, addModel );
		
		addButton.y = 5;			
		addButton.x = 2;			
		addButton.width = btnWidth;
		_buttonContainer.addElement( addButton );
		_buttonContainer.height += addButton.height + pbPadding;
		
		_deleteButton = new Button( LanguageManager.localizedStringGet( "Model_Delete" ) + ".." );
		_deleteButton.y = 30;			
		_deleteButton.x = 2;			
		_deleteButton.width = width - 10;
		_deleteButton.enabled = false;
		_deleteButton.active = false;
		_deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteModelHandler );
		_deleteButton.width = btnWidth;
		_buttonContainer.addElement( _deleteButton );
		_buttonContainer.height += _deleteButton.height + pbPadding;
		
		_detailButton = new Button( LanguageManager.localizedStringGet( "Model_Detail" ) + ".." );
		_detailButton.y = 55;			
		_detailButton.x = 2;			
		_detailButton.width = width - 10;
		_detailButton.enabled = false;
		_detailButton.active = false;
		_detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, function ($e:UIMouseEvent):void { new WindowModelDetail( _selectedModel ); } );
		_detailButton.width = btnWidth;
		_buttonContainer.addElement( _detailButton );
		
		function deleteModelHandler(event:UIMouseEvent):void  {
			if ( _selectedModel )
			{
				// move this item to the players INVENTORY so that is it not "lost"
				Log.out( "PanelModels.deleteModel - " + _selectedModel.toString(), Log.WARN );
//				InventoryModelEvent.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_CHANGE, Network.userId, _selectedModel.instanceInfo.guid, 1 ) );

				_selectedModel.dead = true;
				if ( _selectedModel.associatedGrain && _selectedModel.instanceInfo.controllingModel ) {
					_selectedModel.instanceInfo.controllingModel.write( _selectedModel.associatedGrain, TypeInfo.AIR );
				}
				populateModels( _dictionarySource, _parentModel );
				buttonsDisable();
				UIRegionModelEvent.dispatch( new UIRegionModelEvent( UIRegionModelEvent.SELECTED_MODEL_CHANGED, null, _parentModel ) );
			}
			else
				noModelSelected();
		}
		
		function addModel(event:UIMouseEvent):void { 
			WindowInventoryNew._s_hackShowChildren = true;
			WindowInventoryNew._s_hackSupportClick = true;
			var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_OWNED, WindowInventoryNew.INVENTORY_CAT_MODELS );
			new WindowInventoryNew( startingTab ); 
		}
	}

	private function selectModel(event:ListEvent):void 
	{
		_selectedModel = event.target.data;
		if ( _selectedModel )
		{
			buttonsEnable();
			VoxelModel.selectedModel = _selectedModel
			// TO DO this is the right path, but probably need a custom event for this...
			UIRegionModelEvent.dispatch( new UIRegionModelEvent( UIRegionModelEvent.SELECTED_MODEL_CHANGED, _selectedModel, _parentModel ) );
			//_parent.childPanelAdd( _selectedModel );
			//_parent.animationPanelAdd( _selectedModel );
		}
		else {
			buttonsDisable();
		}
	}
	
	private function buttonsDisable():void {
		_detailButton.enabled = false;
		_detailButton.active = false;
		_deleteButton.enabled = false;
		_deleteButton.active = false;
	}
	
	private function buttonsEnable():void {
		_detailButton.enabled = true;
		_detailButton.active = true;
		_deleteButton.enabled = true;
		_deleteButton.active = true;
	}
	
	private function noModelSelected():void
	{
		(new Alert( LanguageManager.localizedStringGet( "No_Model_Selected" ) )).display();
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