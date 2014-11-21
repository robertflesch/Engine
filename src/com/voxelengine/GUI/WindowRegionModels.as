
package com.voxelengine.GUI
{
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class WindowRegionModels extends VVPopup
	{
		public function WindowRegionModels()
		{
			super( LanguageManager.localizedStringGet( "Voxel_Model" ) );
			autoSize = true;
			//width = 600;
			//height = 400;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			populateTopLevelModels();
			
			buttonsCreate();
			
			display();
			
			//addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelCreated );
        }
		
		private function buttonsCreate():void {
			//const pbWidth:int = 100;
			const pbPadding:int = 10;
			var panelButton:Canvas = new Canvas();
			panelButton.autoSize = true;
			
			panelButton.layout.orientation = LayoutOrientation.HORIZONTAL;
			panelButton.padding = pbPadding;
			addElement( panelButton );

//			if ( true == Globals.g_debug )
//			{
				var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
				oxelUtils.addEventListener(UIMouseEvent.CLICK, oxelUtilsHandler );
				//oxelUtils.width = pbWidth - 2 * pbPadding;
				panelButton.addElement( oxelUtils );
//			}
		}

		private function onParentModelCreated(event:ModelEvent):void {
			
			//_modelPanels[0].update();
			//
			//var guid:String = event.instanceGuid;
			//Log.out( "WindowModels.onParentModelCreated: " + guid );
			//var vm:VoxelModel = Globals.getModelInstance( event.instanceGuid );
			//if ( vm && vm.metadata && "" != vm.metadata.name && false == vm.metadata.template )
				//_listParents.addItem( vm.metadata.name, vm );
			
			//populateParentModels();
		}

		
		private function populateTopLevelModels():void
		{
			// Popup is NOT a UIContainer for some reason.
			// So we have to create this holding object for all of the panels
			// so that they may resize correctly
			var panelCanvas:PanelBase = new PanelBase( null, width, height );
			panelCanvas.layout.orientation = LayoutOrientation.HORIZONTAL;
			addElement( panelCanvas );
			
			var modelPanel:PanelModelAnimations = new PanelModelAnimations( panelCanvas );
			modelPanel.updateChildren( Globals.modelInstancesGetDictionary, null );
			panelCanvas.addElement( modelPanel );
		}
		
		private function oxelUtilsHandler(event:UIMouseEvent):void  {

			if ( Globals.selectedModel )
				new WindowOxelUtils( Globals.selectedModel );
			else
				noModelSelected();
		}
		
		
		private function noModelSelected():void
		{
			(new Alert( LanguageManager.localizedStringGet( "No_Model_Selected" ) )).display();
		}
		
		public function recalc( $width:Number, $height:Number ):void {
			if ( width < $width || height < $height ) {
				resize( $width, $height );
			}
		}
	}
}