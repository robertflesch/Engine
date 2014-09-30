
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
			
			if ( Network._userId == "simpleBob" ) {
				var addDeskTopModel:Button = new Button( "Add Desktop Model" );
				addDeskTopModel.addEventListener(UIMouseEvent.CLICK, addDesktopModelHandler );
				panelParentButton.addElement( addDeskTopModel );
			}
			
			var addModel:Button = new Button( "Add This Model" );
			addModel.addEventListener(UIMouseEvent.CLICK, addThisModelHandler );
			panelParentButton.addElement( addModel );
			
			var cancel:Button = new Button( "Cancel" );
			cancel.addEventListener(UIMouseEvent.CLICK, cancelSelection );
			panelParentButton.addElement( cancel );
			
			display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			
			Globals.g_app.addEventListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, modelLoaded );
			Globals.g_app.addEventListener( LoadingEvent.TEMPLATE_MODEL_COMPLETE, newTemplateLoaded );
			populateModels();
        }
		
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
			Globals.g_app.removeEventListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, modelLoaded );
			removeEventListener(UIOEvent.REMOVED, onRemoved );
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
		
		private function addThisModelHandler( event:UIMouseEvent ):void 
		{
			if ( -1 == _listbox1.selectedIndex )
				return;
			var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
			if ( li && li.data )
			{
				var vmm:VoxelModelMetadata = li.data as VoxelModelMetadata;
				//vmm = vmm.clone();
				// So if I see the database object to null. And give it a new guid, I have a nice copy ;-)
//				vmm.databaseObject = null;
				// no longer based on a template
//				vmm.template = false;
				// we will track where it came from since we might want to return it to pool.
//				vmm.templateGuid = vmm.guid;
//				vmm.guid = Globals.getUID();
				var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( vmm, _parentGuid );				
//				vm.changed = true;
//				vm.save();

				remove();
			}
		}
		
		private function cancelSelection(event:UIMouseEvent):void 
		{
			remove();
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