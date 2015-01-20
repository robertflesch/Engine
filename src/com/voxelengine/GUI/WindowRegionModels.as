
package com.voxelengine.GUI
{
	import com.voxelengine.events.InventoryVoxelEvent;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.models.VoxelModel;
	
	public class WindowRegionModels extends VVPopup
	{
		private var _modelPanel:PanelModelAnimations;
		
		public function WindowRegionModels()
		{
			super( LanguageManager.localizedStringGet( "Voxel_Model" ) );
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			createTopLevel();
			display();
			
			Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
        }
		
		private function onParentModelAdded(event:ModelEvent):void {
			
			// TODO - Handle new models being added to system
			Log.out( "WindowRegionModels.onParentModelAdded - NEED A HANDLER SOMEWHERE?", Log.WARN );
			if ( _modelPanel )
				_modelPanel.updateChildren( Globals.modelInstancesGetDictionary, null );
		}
		
		override protected function onRemoved(event:UIOEvent):void 
		{
			Log.out( "WindowRegionModels.onRemoved", Log.WARN );
			super.onRemoved(event);
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
			
			_modelPanel.close();
		}

		
		private function createTopLevel():void
		{
			// Popup is NOT a UIContainer for some reason.
			// So we have to create this holding object for all of the panels
			// so that they may resize correctly
			var panelCanvas:PanelBase = new PanelBase( null, width, height, BorderStyle.NONE );
			panelCanvas.layout.orientation = LayoutOrientation.HORIZONTAL;
			addElement( panelCanvas );
			
			_modelPanel = new PanelModelAnimations( panelCanvas );
			_modelPanel.updateChildren( Globals.modelInstancesGetDictionary, null );
			panelCanvas.addElement( _modelPanel );
		}
	}
}