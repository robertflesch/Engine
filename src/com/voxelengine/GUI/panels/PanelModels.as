/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.events.InventoryModelEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.worldmodel.models.ModelCache;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;

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
	private var _buttonContainer:Container

	private var _dupButton:Button
	private var _detailButton:Button
	private var _deleteButton:Button
	
	public function PanelModels( $parent:PanelModelAnimations, $widthParam:Number, $elementHeight:Number, $heightParam:Number )	{
		super( $parent, $widthParam, $heightParam );
		_parent = $parent;
		
		//Log.out( "PanelModels - list box width: width: " + width + "  padding: " + pbPadding, Log.WARN );
		_listModels = new ListBox( width - pbPadding, $elementHeight, $heightParam );
		_listModels.dragEnabled = true;
		_listModels.draggable = true;

		_listModels.eventCollector.addEvent( _listModels, ListEvent.ITEM_PRESSED, selectModel );		
		ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged )
		
		buttonsCreate();
		addElement( _listModels );

		//ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.DELETE, 0, _modelGuid, null ) );
		ModelInfoEvent.addListener( ModelBaseEvent.DELETE, modelDeletedGlobally );
		
		// ALL DRAG AND DROP methods, which are not working
		//_listModels.dndData
		//_listModels.eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		//_listModels.eventCollector.addEvent( this, ListEvent.ITEM_PRESSED, doDrag);
		//addListeners();
		
		//_listModels.eventCollector.addEvent( _listModels, ListEvent.LIST_CHANGED, function( $le:ListEvent ):void { Log.out( "PanelModel.listModelEvent - LIST_CHANGED $le: " + $le ) } )		
		//_listModels.eventCollector.addEvent( _listModels, ListEvent.EDITED, function( $le:ListEvent ):void { Log.out( "PanelModel.listModelEvent - EDITED $le: " + $le ) } )		
		//_listModels.eventCollector.addEvent( _listModels, ListEvent.ITEM_CLICKED, function( $le:ListEvent ):void { Log.out( "PanelModel.listModelEvent - ITEM_CLICKED $le: " + $le ) } )		
		//_listModels.eventCollector.addEvent( _listModels, ListEvent.ITEM_PRESSED, function( $le:ListEvent ):void { Log.out( "PanelModel.listModelEvent - ITEM_PRESSED $le: " + $le ) } )		
		//_listModels.eventCollector.addEvent( _listModels, ListEvent.DATA_PROVIDER_CHANGED, function( $le:ListEvent ):void { Log.out( "PanelModel.listModelEvent - DATA_PROVIDER_CHANGED $le: " + $le ) } )		
	}

	private function modelDeletedGlobally( e:ModelInfoEvent ): void {
		var modelFound:Boolean = true;
		for ( var i:int; i < _listModels.length; i++ ) {
			var listItem:ListItem = _listModels.getItemAt( i );
			var vm:VoxelModel = listItem.data as VoxelModel;
			if ( e.modelGuid == vm.modelInfo.guid ) {
				_listModels.removeItemAt( i );
				modelFound = true;
				break;
			}
		}

		if ( modelFound && vm ) {
			UIRegionModelEvent.dispatch(new UIRegionModelEvent(UIRegionModelEvent.SELECTED_MODEL_CHANGED, vm, _parentModel));
			// remove inventory
			InventoryModelEvent.dispatch( new InventoryModelEvent( ModelBaseEvent.DELETE, "", vm.instanceInfo.instanceGuid, null ) )
		}
	}
	
	override public function close():void {
		super.close();
		_listModels.removeEventListener( ListEvent.LIST_CHANGED, selectModel );		
		
		_parentModel = null;
		_dictionarySource = null;
	}
	
	public function populateModels( $source:Function, $parentModel:VoxelModel ):int	{
		//Log.out( "PanelModels.populateModels - parentModel:" + $parentModel, Log.WARN )
		_dictionarySource = $source;
		_parentModel = $parentModel;
		_listModels.removeAll();
		var countAdded:int;
		for each ( var vm:VoxelModel in _dictionarySource() )
		{
			if ( vm && !vm.instanceInfo.dynamicObject && !vm.dead )
			{
				if ( !Globals.isDebug ) {
					if ( vm is Player )
						continue;
				}
				var itemName:String = "";
				if ( vm.metadata.name )
					itemName = vm.metadata.name;
				else	
					itemName = vm.modelInfo.guid;
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

		var addButton:Button = new Button( LanguageManager.localizedStringGet( "Model_Add" )  );
		//addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowModelList(); } );
		addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, addModel );
		
		addButton.y = 5;			
		addButton.x = 2;			
		addButton.width = btnWidth;
		_buttonContainer.addElement( addButton );
		_buttonContainer.height += addButton.height + pbPadding;
		
		_deleteButton = new Button( LanguageManager.localizedStringGet( "Model_Delete" ) );
		_deleteButton.y = 30;			
		_deleteButton.x = 2;			
		_deleteButton.width = width - 10;
		_deleteButton.enabled = false;
		_deleteButton.active = false;
		_deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteModelHandler );
		_deleteButton.width = btnWidth;
		_buttonContainer.addElement( _deleteButton );
		_buttonContainer.height += _deleteButton.height + pbPadding;
		
		_detailButton = new Button( LanguageManager.localizedStringGet( "Model_Detail" ) );
		_detailButton.y = 55;			
		_detailButton.x = 2;			
		_detailButton.width = width - 10;
		_detailButton.enabled = false;
		_detailButton.active = false;
		_detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, function ($e:UIMouseEvent):void { new WindowModelDetail( VoxelModel.selectedModel ); } );
		_detailButton.width = btnWidth;
		_buttonContainer.addElement( _detailButton );

		if ( Globals.isDebug ) {
			_dupButton = new Button( LanguageManager.localizedStringGet( "DUP" ) );
			_dupButton.y = 75;
			_dupButton.x = 2;
			_dupButton.width = width - 10;
			_dupButton.enabled = true;
			_dupButton.active = true;
			_dupButton.eventCollector.addEvent( _dupButton, UIMouseEvent.CLICK, dupModel );
			_dupButton.width = btnWidth;
			_buttonContainer.addElement( _dupButton );

		}

		function dupModel(event:UIMouseEvent):void  {
			new ModelMakerClone(  VoxelModel.selectedModel, false );
		}

		function deleteModelHandler(event:UIMouseEvent):void  {
			if ( VoxelModel.selectedModel )
				deleteModelCheck()
			else
				noModelSelected();
			
			function deleteModelCheck():void {
				var alert:Alert = new Alert( "Do you really want to delete the model '" + VoxelModel.selectedModel.metadata.name + "'?", 400 )
				alert.setLabels( "Yes", "No" );
				alert.alertMode = AlertMode.CHOICE;
				$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
				alert.display();
				
				function alertAction( $ae:AlertEvent ):void {
					if ( AlertEvent.ACTION == $ae.action )
						deleteElement()
					else ( AlertEvent.CHOICE == $ae.action )
						doNotDelete()
				}
				
				function doNotDelete():void { /* do nothing */ }
			}
			
			function deleteElement():void {
				Log.out( "PanelModels.deleteModel - " + VoxelModel.selectedModel.toString(), Log.WARN );
				ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved )
				if ( VoxelModel.selectedModel.associatedGrain && VoxelModel.selectedModel.instanceInfo.controllingModel ) {
					VoxelModel.selectedModel.instanceInfo.controllingModel.write( VoxelModel.selectedModel.associatedGrain, TypeInfo.AIR );
				}
				VoxelModel.selectedModel.dead = true;
				populateModels( _dictionarySource, _parentModel );
				buttonsDisable();
				UIRegionModelEvent.dispatch( new UIRegionModelEvent( UIRegionModelEvent.SELECTED_MODEL_CHANGED, null, _parentModel ) );
//				InventoryModelEvent.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_CHANGE, Network.userId, _selectedModel.instanceInfo.guid, 1 ) );
			}
		}
		
		function modelRemoved( $me:ModelEvent ):void {
			if ( $me.instanceGuid == VoxelModel.selectedModel.instanceInfo.instanceGuid ) {
				ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved )
				if ( null == _parentModel ) {
					VoxelModel.selectedModel.selected = false
					VoxelModel.selectedModel = null
				}
			}
		}

		function addModel(event:UIMouseEvent):void { 
			if ( VoxelModel.selectedModel && null != VoxelModel.selectedModel.instanceInfo.controllingModel )
				WindowInventoryNew._s_hackShowChildren = true;
			else
				WindowInventoryNew._s_hackShowChildren = false;
			WindowInventoryNew._s_hackSupportClick = true;
			var startingTab:String = WindowInventoryNew.makeStartingTabString( WindowInventoryNew.INVENTORY_OWNED, WindowInventoryNew.INVENTORY_CAT_MODELS );
			WindowInventoryNew.toggle( startingTab )
		}
	}

	private function metadataChanged( $mme:ModelMetadataEvent ):void {
		
		//if ( $mme.modelGuid == om.modelGuid ) {
			//ModelMetadataEvent.removeListener( ModelBaseEvent.CHANGED, metadataChanged )
			//om.vmm = $mme.modelMetadata
			//updateObjectInfo( om )
		//}
		for ( var i:int; i < _listModels.length; i++ ) {
			var listItem:ListItem = _listModels.getItemAt( i )
			var vm:VoxelModel = listItem.data as VoxelModel
			if ( $mme.modelGuid == vm.modelInfo.guid ) {
				//_listModels.removeItemAt( i )
				_listModels.updateItemAt( i, vm.metadata.name, vm )
			}
		}
		
	}

	import flash.utils.getTimer;
	private var doubleMessageHackTime:int = getTimer();
	private function get doubleMessageHack():Boolean {
		var newTime:int = getTimer();
		var result:Boolean = false;
		if ( doubleMessageHackTime + Globals.DOUBLE_MESSAGE_WAITING_PERIOD * 10 < newTime ) {
			doubleMessageHackTime = newTime;
			result = true;
		}
		return result;
	}
	private function selectModel(event:ListEvent):void {
		if ( doubleMessageHack ) {
			if (event.target.data) {
				Log.out("PanelModels.selectModel has TARGET DATA");
				buttonsEnable();
				VoxelModel.selectedModel = event.target.data
				// TO DO this is the right path, but probably need a custom event for this...
				UIRegionModelEvent.dispatch(new UIRegionModelEvent(UIRegionModelEvent.SELECTED_MODEL_CHANGED, VoxelModel.selectedModel, _parentModel));
				//_parent.childPanelAdd( _selectedModel );
				//_parent.animationPanelAdd( _selectedModel );
			}
			else {
				Log.out("PanelModels.selectModel has NO target data");
				buttonsDisable();
			}
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
	
	private function noModelSelected():void	{
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