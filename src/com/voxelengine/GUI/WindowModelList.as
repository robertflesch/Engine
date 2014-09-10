
package com.voxelengine.GUI
{

	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.server.Persistance;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import flash.utils.ByteArray;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.events.Event;
	import flash.net.FileFilter;
	
	import flash.utils.Dictionary;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	public class WindowModelList extends VVPopup
	{
		private var _modelKey:String;
		private const _TOTAL_LB_WIDTH:int = 400;
		private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 100;
		
		private var _listbox1:ListBox = new ListBox( _TOTAL_LB_WIDTH, 15 );
		
		public function WindowModelList()
		{
			super("Model List");
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
			fr.addEventListener(Event.SELECT, onChildModelFileSelected);
			var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.mjson");
			fr.browse([swfTypeFilter]);
		}
		
		public function onChildModelFileSelected(e:Event):void
		{
			Log.out( "onChildModelFileSelected : " + e.toString() );
			
			var fileName:String = e.currentTarget.name;
			fileName = fileName.substr( 0, fileName.indexOf( "." ) );

			new WindowModelMetadata( fileName );
			remove();
		}
		
		private function addThisModelHandler( event:UIMouseEvent ):void 
		{
			// Globals.GUIControl = true;
			if ( -1 == _listbox1.selectedIndex )
				return;
			var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
			if ( li && li.data )
			{
				var mmde:ModelMetadataEvent = li.data as ModelMetadataEvent;
				var ba:ByteArray = mmde.ba as ByteArray;
				ba.uncompress();
				var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( ba, mmde.guid );				

				remove();
			}
		}
		
		private function cancelSelection(event:UIMouseEvent):void 
		{
			remove();
		}
		
		private function modelLoaded( e:ModelMetadataEvent ):void
		{
			_listbox1.addItem( e.name + " - " + e.description, e );
		}
		
		private function populateModels():void
		{
			Persistance.loadPublicObjectsMetadata();
			Persistance.loadUserObjectsMetadata( Network.userId );
			_listbox1.removeAll();
			var models:Dictionary = Globals.modelInstancesGetDictionary();
			for each ( var vm:VoxelModel in models )
			{
				if ( vm && !vm.instanceInfo.dynamicObject && !vm.instanceInfo.dead )
				{
					if ( vm is Player )
						continue;
						
					_listbox1.addItem( vm.instanceInfo.name, vm );
				}
			}
			
		}
	}
}