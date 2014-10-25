
package com.voxelengine.GUI
{
	import org.flashapi.swing.Popup;
    import org.flashapi.swing.event.UIOEvent;
    import org.flashapi.swing.constants.LayoutOrientation;
	
	import com.voxelengine.worldmodel.models.VoxelModel;
	
	public class WindowModelTemplate extends VVPopup
	{
		static public const PANEL_WIDTH:int = 220;
		static public const PANEL_HEIGHT:int = 400;
		//private var _mi:ModelInfo = null;
		
		public function WindowModelTemplate( $vm:VoxelModel )
		{
			super( "Model Template" );
			//_mi = $mi;
			autoSize = true;
			layout.orientation = LayoutOrientation.HORIZONTAL;
			
//			this.addElement( new PanelModelInfoDetail( PANEL_WIDTH, PANEL_HEIGHT, _mi ) );
//			this.addElement( new PanelProcedurallyGeneratedModel( PANEL_WIDTH, PANEL_HEIGHT, _mi ) );
//			this.addElement( new PanelChildModels( PANEL_WIDTH, PANEL_HEIGHT, _mi ) );			
			
			display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
        }
  }
}
