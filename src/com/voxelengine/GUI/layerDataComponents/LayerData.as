
package com.voxelengine.GUI.layerDataComponents
{
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.containers.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	public class LayerData extends SimpleContainerBase
	{
		public function LayerData( $label:String, $value:String, callBack:Function, $width:int = 180, $height:int = 20 ):void
		{
			super( $width, $height );
			padding = 0;
			//var compWidth = $width - 60;
			addElement( new Label( $label, 140 ) );
			var ti:TextInput = new TextInput( $value, 60 );
			ti.data = $label;
			addElement( ti );
			//worker.myEventCollector.addEvent( Text
			ti.addEventListener( TextEvent.EDITED, callBack );
		}
	}
}

