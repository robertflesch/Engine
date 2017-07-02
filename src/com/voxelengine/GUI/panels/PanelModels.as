/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.event.ListEvent;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.UIRegionModelEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.inventory.WindowInventoryNew;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;

import org.flashapi.swing.text.UITextField;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModels extends PanelBase
{
	private var _parentModel:VoxelModel;
	private var _listModels:ListBox;
	private var _dictionarySource:Function;
	private var _level:int;
	private var _selectedText:Text

	private var _dupButton:Button;
	private var _detailButton:Button;
	private var _deleteButton:Button;
	
	public function PanelModels($parent:ContainerModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number, $level:int )	{
		super( $parent, $widthParam, $heightParam );
		width = $widthParam;
		height = $heightParam;
		_parent = $parent;
		_level = $level;
		autoHeight = false;
		layout = new AbsoluteLayout();

		//Log.out( "PanelModels - list box width: width: " + width + "  padding: " + pbPadding, Log.WARN );
		_listModels = new ListBox( width - 10, $elementHeight, $heightParam );
		_listModels.x = 5;
//		_listModels.dragEnabled = true;
//		_listModels.draggable = true;

		_listModels.eventCollector.addEvent( _listModels, ListEvent.ITEM_PRESSED, selectModel );
		//ModelMetadataEvent.addListener( ModelBaseEvent.IMPORT_COMPLETE, metadataImported );
		ModelEvent.addListener( ModelEvent.CHILD_MODEL_ADDED, childModelAdded );
		ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED, parentModelAdded );

		var bHeight:int = buttonsCreate();
		_listModels.y = bHeight;
		height =  _listModels.y + _listModels.height + 10;
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

	// This model is being removed from the library of models, remove all instances of it.
	private function modelDeletedGlobally( e:ModelInfoEvent ): void {
		var modelFound:Boolean = true;
		for ( var i:int = 0; i < _listModels.length; i++ ) {
			var guids:Object = getItem( i );
			if ( e.modelGuid == guids.modelGuid ) {
				_listModels.removeItemAt( i );
				modelFound = true;
				if ( VoxelModel.selectedModel && VoxelModel.selectedModel.modelInfo == guids.modelInfo ) {
					VoxelModel.selectedModel = null;
					_selectedText.text = "Previous Model Deleted";
				}
			}
		}
/*
		if ( modelFound && vm ) {
			UIRegionModelEvent.create(UIRegionModelEvent.SELECTED_MODEL_REMOVED, vm, _parentModel, +_level );
		}
*/
	}
	
	override public function close():void {
		super.close();
		_listModels.removeEventListener( ListEvent.LIST_CHANGED, selectModel );
		//ModelMetadataEvent.removeListener( ModelBaseEvent.IMPORT_COMPLETE, metadataImported );

		_parentModel = null;
		_dictionarySource = null;
	}
	
	public function populateModels( $source:Function, $parentModel:VoxelModel ):int	{
		//Log.out( "PanelModels.populateModels - parentModel:" + $parentModel, Log.WARN )
		_dictionarySource = $source;
		_parentModel = $parentModel;
		_selectedText.text = "Nothing Selected";
		if ( _listModels )
			_listModels.removeAll();

		var countAdded:int = 0;
		for each ( var vm:VoxelModel in _dictionarySource() )
		{
			if ( vm && !vm.instanceInfo.dynamicObject && !vm.dead ) {
//				if ( !Globals.isDebug ) {
//					if ( vm is Player )
//						continue;
//				}
				var itemName:String = "";
				if ( vm.instanceInfo.name )
					itemName = vm.instanceInfo.name;
				else if ( vm.metadata.name )
					itemName = vm.metadata.name;
				else
					itemName = vm.modelInfo.guid;
				//Log.out( "PanelModels.populateModels - adding: " + itemName );

				addItem( itemName, vm.instanceInfo.instanceGuid, vm.modelInfo.guid );
				countAdded++;
			}
		}
		buttonsDisable();
		return countAdded;
	}

	private function addItem( $name:String, $instanceGuid:String, $modelGuid:String ):void {
		_listModels.addItem( $name, { "instanceGuid" : $instanceGuid, "modelGuid" : $modelGuid } );
	}

	private function getItem( $index:int ):Object {
		var listItem:ListItem = _listModels.getItemAt( $index );
		if ( listItem )
			return listItem.data as Object;
		else
			return { "instanceGuid" : "", "modelGuid" : "" };
	}

	//// FIXME This would be much better with drag and drop
	// meaning removing the buttons completely
	private function buttonsCreate():int {
		
		const btnWidth:int = width - 10;
		var container:Container;

		//Log.out( "PanelModels.buttonsCreate" );
		container = new Container( width, 10 );
		//container.layout.orientation = LayoutOrientation.VERTICAL;
		container.layout = new AbsoluteLayout();
		container.padding = 0;
		container.height = 0;
		addElementAt( container, 0 );
		const BUTTON_DISTANCE:int = 25;
		var currentY:int = 5;

		_selectedText = new Text( width, 30 );
		_selectedText.text = "Nothing Selected";
		_selectedText.textAlign = TextAlign.CENTER;
		container.addElement( _selectedText );
		_selectedText.y = currentY;
		_selectedText.x = 5;

		var addButton:Button = new Button( LanguageManager.localizedStringGet( "Model_Add" )  );
		//addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowModelList(); } );
		addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, addModel );
		
		addButton.y = currentY = currentY + BUTTON_DISTANCE;
		addButton.x = 5;
		addButton.width = btnWidth;
		container.addElement( addButton );
		container.height += addButton.height + pbPadding;
		
		_deleteButton = new Button( LanguageManager.localizedStringGet( "Model_Delete" ) );
		_deleteButton.y = currentY = currentY + BUTTON_DISTANCE;
		_deleteButton.x = 5;
		_deleteButton.width = btnWidth;
		_deleteButton.enabled = false;
		_deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteModelHandler );
		_deleteButton.width = btnWidth;
		container.addElement( _deleteButton );
		container.height += _deleteButton.height + pbPadding;
		
		_detailButton = new Button( LanguageManager.localizedStringGet( "instance_details" ) );
		_detailButton.y = currentY = currentY + BUTTON_DISTANCE;
		_detailButton.x = 5;
		_detailButton.width = btnWidth;
		_detailButton.enabled = false;
		_detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, function ($e:UIMouseEvent):void { new WindowModelDetail( VoxelModel.selectedModel ); } );
		container.addElement( _detailButton );

		if ( Globals.isDebug ) {
			_dupButton = new Button( LanguageManager.localizedStringGet( "DUP" ) );
			_dupButton.y = currentY = currentY + BUTTON_DISTANCE;
			_dupButton.x = 5;
			_dupButton.width = btnWidth;
			_dupButton.enabled = false;
			_dupButton.eventCollector.addEvent( _dupButton, UIMouseEvent.CLICK, dupModel );
			container.addElement( _dupButton );

		}

		return currentY + BUTTON_DISTANCE;

		function dupModel(event:UIMouseEvent):void  {
			if ( VoxelModel.selectedModel )
				new ModelMakerClone(  VoxelModel.selectedModel, false );
		}

		function deleteModelHandler(event:UIMouseEvent):void  {
			if ( VoxelModel.selectedModel )
				deleteModelCheck();
			else
				noModelSelected();
			
			function deleteModelCheck():void {
				var alert:Alert = new Alert( "Do you really want to delete the model '" + VoxelModel.selectedModel.metadata.name + "'?", 400 );
				alert.setLabels( "Yes", "No" );
				alert.alertMode = AlertMode.CHOICE;
				$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
				alert.display();
				
				function alertAction( $ae:AlertEvent ):void {
					if ( AlertEvent.ACTION == $ae.action )
						deleteElement();
					else if ( AlertEvent.CHOICE == $ae.action )
						doNotDelete();
				}
				
				function doNotDelete():void { /* do nothing */ }
			}
			
			function deleteElement():void {
				Log.out( "PanelModels.deleteModel - " + VoxelModel.selectedModel.toString(), Log.WARN );
				ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved );
				if ( VoxelModel.selectedModel.instanceInfo.associatedGrain && VoxelModel.selectedModel.instanceInfo.controllingModel ) {
					VoxelModel.selectedModel.instanceInfo.controllingModel.write( VoxelModel.selectedModel.instanceInfo.associatedGrain, TypeInfo.AIR );
				}
				VoxelModel.selectedModel.dead = true;
				populateModels( _dictionarySource, _parentModel );
				buttonsDisable();
				UIRegionModelEvent.create( UIRegionModelEvent.SELECTED_MODEL_CHANGED, null, _parentModel, _level );
//				InventoryModelEvent.dispatch( new InventoryModelEvent( InventoryModelEvent.INVENTORY_MODEL_CHANGE, Network.userId, _selectedModel.instanceInfo.guid, 1 ) );
			}
		}
		
		function modelRemoved( $me:ModelEvent ):void {
			if ( VoxelModel.selectedModel && $me.instanceGuid == VoxelModel.selectedModel.instanceInfo.instanceGuid ) {
				ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved );
				if ( null == _parentModel ) {
					VoxelModel.selectedModel.selected = false;
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

	//ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
//	private function metadataImported( $mme:ModelMetadataEvent ):void {
//		var instances:Vector.<VoxelModel> = Region.currentRegion.modelCache.instancesOfModelGet( $mme.modelGuid );
//		// should be one if I just imported it.
//		for each ( var vm:VoxelModel in instances ){
//			addItem( vm.metadata.name, vm.instanceInfo.instanceGuid, vm.modelInfo.guid );
//		}
//	}

	private function selectModel(event:ListEvent):void {
			//Log.out("PanelModels.selectModel - AFTER Double");
			if (event.target.data) {
				var instanceGuid:String = event.target.data.instanceGuid;
				Log.out("PanelModels.selectModel has TARGET DATA: " + event.target.data as String);
				displayModelData( instanceGuid );
			}
			else {
				Log.out("PanelModels.selectModel has NO target data");
				buttonsDisable();
				VoxelModel.selectedModel = null;
				_selectedText.text = "Nothing Selected";
				UIRegionModelEvent.create( UIRegionModelEvent.SELECTED_MODEL_CHANGED, null, null, _level);
			}
	}

	private function displayModelData( $instanceGuid:String ):void {
		buttonsEnable();
		var vm:VoxelModel;
		if ( null == _parentModel )
			vm = Region.currentRegion.modelCache.instanceGet( $instanceGuid );
		else
			vm = _parentModel.childFindInstanceGuid( $instanceGuid );
		Log.out("PanelModels.selectModel vm: " + vm );
		if ( vm ) {
			VoxelModel.selectedModel = vm;
			_selectedText.text = vm.metadata.name;
			Log.out("PanelModels.selectModel vm.metadata.name: " + vm.metadata.name );
			// TO DO this is the right path, but probably need a custom event for this...
			UIRegionModelEvent.create( UIRegionModelEvent.SELECTED_MODEL_CHANGED, vm, _parentModel, _level);
			//_parent.childPanelAdd( _selectedModel );
			//_parent.animationPanelAdd( _selectedModel );
		} else
			buttonsDisable();
	}
	
	private function buttonsDisable():void {
		_detailButton.enabled = false;
		_detailButton.active = false;
		_deleteButton.enabled = false;
		_deleteButton.active = false;
		if ( _dupButton ) {
			_dupButton.enabled = false;
			_dupButton.active = false;
		}
	}
	
	private function buttonsEnable():void {
		_detailButton.enabled = true;
		_detailButton.active = true;
		_deleteButton.enabled = true;
		_deleteButton.active = true;
		if ( _dupButton ) {
			_dupButton.enabled = true;
			_dupButton.active = true;
		}
	}
	
	static private function noModelSelected():void	{
		(new Alert( LanguageManager.localizedStringGet( "No_Model_Selected" ) )).display();
	}

	private function childModelAdded( $me:ModelEvent ):void {
		if ( 0 == _level )
				return;
		var pig:String = $me.parentInstanceGuid;
		var ig:String = $me.instanceGuid;
		var vm:VoxelModel = $me.vm;
		if ( vm && _parentModel && pig == _parentModel.instanceInfo.instanceGuid )
			addItem( vm.metadata.name, vm.instanceInfo.instanceGuid, vm.modelInfo.guid );
	}

	private function parentModelAdded( $me:ModelEvent ):void {
		if ( 0 <= _level )
			return;
		var ig:String = $me.instanceGuid;
		var vm:VoxelModel = $me.vm;
		if ( vm )
			addItem( vm.metadata.name, vm.instanceInfo.instanceGuid, vm.modelInfo.guid );

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