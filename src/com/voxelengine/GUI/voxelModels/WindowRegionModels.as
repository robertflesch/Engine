
package com.voxelengine.GUI.voxelModels
{
	import com.voxelengine.events.CursorOperationEvent;
	import com.voxelengine.GUI.panels.PanelBase;
	import com.voxelengine.GUI.panels.PanelModelDetails;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.Region;
	
	public class WindowRegionModels extends VVPopup
	{
		private var _modelPanel:PanelModelDetails;

		static public var _s_instance:WindowRegionModels;
		
		static public function toggle():void {
			if ( null == _s_instance )
				_s_instance = new WindowRegionModels()
			else {
				_s_instance.remove()
				_s_instance = null
			}
		}
		
		public function WindowRegionModels()
		{
			super( LanguageManager.localizedStringGet( "Voxel_Model" ) );
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			createTopLevel();
			display();
			
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
			CursorOperationEvent.dispatch( new CursorOperationEvent( CursorOperationEvent.NONE ) )
        }
		
		private function onParentModelAdded(event:ModelEvent):void {
			if ( _modelPanel )
				_modelPanel.updateChildren( Region.currentRegion.modelCache.modelsGet, null );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid ) );
		}
		
		override protected function onRemoved(event:UIOEvent):void 
		{
			Log.out( "WindowRegionModels.onRemoved", Log.WARN );
			super.onRemoved(event);
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelAdded );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, 0, null ));
			
			_modelPanel.close();
			
			_s_instance = null
		}

		
		private function createTopLevel():void
		{
			// Popup is NOT a UIContainer for some reason.
			// So we have to create this holding object for all of the panels
			// so that they may resize correctly
			var panelCanvas:PanelBase = new PanelBase( null, width, height, BorderStyle.NONE );
			panelCanvas.layout.orientation = LayoutOrientation.HORIZONTAL;
			addElement( panelCanvas );
			
			_modelPanel = new PanelModelDetails( panelCanvas );
			_modelPanel.updateChildren( Region.currentRegion.modelCache.modelsGet, null );
			panelCanvas.addElement( _modelPanel );
		}
	}
}