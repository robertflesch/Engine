/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
	import com.voxelengine.worldmodel.models.TemplateManager;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.server.PersistModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	
	public class WindowModelList extends VVPopup
	{
		private const _TOTAL_LB_WIDTH:int = 400;
		private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 100;
		private var _modelKey:String;
		private var _parentGuid:String;
		
		private var _listbox1:ListBox = new ListBox( _TOTAL_LB_WIDTH, 15 );
		
		public function WindowModelList( $parentGuid:String = "" )
		{
			super("Model List");
			_parentGuid = $parentGuid;
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			addElement( _listbox1 );
			_listbox1.addEventListener(ListEvent.LIST_CHANGED, selectModel);
			
			var panelParentButton:Panel = new Panel( _TOTAL_LB_WIDTH, _TOTAL_BUTTON_PANEL_HEIGHT );
			panelParentButton.layout.orientation = LayoutOrientation.VERTICAL;
			panelParentButton.padding = 2;
			addElement( panelParentButton );
			
			var addModel:Button = new Button( "Add This Model" );
			addModel.addEventListener(UIMouseEvent.CLICK, createInstanceFromTemplate );
			panelParentButton.addElement( addModel );
			
			var newModel:Button = new Button( LanguageManager.localizedStringGet( "New_Model" ));
			newModel.addEventListener(UIMouseEvent.CLICK, newModelHandler );
			//newModel.width = pbWidth - 2 * pbPadding;
			panelParentButton.addElement( newModel );
			
			if ( Globals.g_debug ) {
				var addDeskTopModel:Button = new Button( "Add Desktop Model" );
				addDeskTopModel.addEventListener(UIMouseEvent.CLICK, addDesktopModelHandler );
				panelParentButton.addElement( addDeskTopModel );
			}
			
			display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			
			Globals.g_app.addEventListener( ModelMetadataEvent.INFO_TEMPLATE_REPO, modelLoaded );
			Globals.g_app.addEventListener( LoadingEvent.TEMPLATE_MODEL_COMPLETE, newTemplateLoaded );
			populateModels();
        }
		

		private function newModelHandler(event:UIMouseEvent):void 
		{
			new WindowModelChoice();
		}
		
		
		private function selectModel(event:ListEvent):void 
		{
			_modelKey = event.target.data;
		}

		private function addDesktopModelHandler(event:UIMouseEvent):void 
		{
			var fr:FileReference = new FileReference();
			fr.addEventListener(Event.SELECT, onDesktopModelFileSelected );
			var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.mjson");
			fr.browse([swfTypeFilter]);
		}
		
		public function onDesktopModelFileSelected(e:Event):void
		{
			Log.out( "onDesktopModelFileSelected : " + e.toString() );
			
			//if ( selectedModel
			var fileName:String = e.currentTarget.name;
			fileName = fileName.substr( 0, fileName.indexOf( "." ) );

			new WindowModelMetadata( fileName );
		//	remove();
		}
		
		private function createInstanceFromTemplate( event:UIMouseEvent ):void 
		{
			if ( -1 == _listbox1.selectedIndex )
				return;
			var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
			if ( li && li.data )
			{
				var tvmm:VoxelModelMetadata = li.data as VoxelModelMetadata;
				var vmm:VoxelModelMetadata = tvmm.createInstanceOfTemplate();
				var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( vmm, tvmm.data, _parentGuid );				
				vm.changed = true;
				vm.save( true );

				remove();
			}
		}
		
		private function modelLoaded( e:ModelMetadataEvent ):void
		{
			_listbox1.addItem( e.vmm.name + " - " + e.vmm.description, e.vmm );
		}
		
		private function newTemplateLoaded( $e:LoadingEvent ):void {
			var vmm:VoxelModelMetadata = TemplateManager.templateGet( $e.guid );
			Log.out( "WindowModelList.newTemplateLoaded name: " + vmm.name + " - " + vmm.description );
			_listbox1.addItem( vmm.name + " - " + vmm.description, vmm );
		}
	
	
		
		
		private function populateModels():void
		{
			_listbox1.removeAll();
			TemplateManager.templatesLoad();

			//PersistModel.loadModels( Network.PUBLIC );
			//PersistModel.loadModels( Network.userId );
			//var models:Dictionary = Globals.modelInstancesGetDictionary();
			//for each ( var vm:VoxelModel in models )
			//{
				//if ( vm && !vm.instanceInfo.dynamicObject && !vm.instanceInfo.dead )
				//{
					//if ( vm is Player )
						//continue;
						//
					//_listbox1.addItem( vm.instanceInfo.name, vm );
				//}
			//}
		}
	}
}