
package com.voxelengine.GUI.voxelModels
{
	import com.voxelengine.events.InventoryVoxelEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.Region;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.GUI.*;
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
			
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
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
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, null ));
			
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