
package com.voxelengine.GUI
{
import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.Container;

import com.voxelengine.Globals;

public class VVContainer extends Container
{
	protected var _parent:VVContainer;
	public function VVContainer( $parent:VVContainer ):void 
	{ 
		_parent = $parent;
		super();
//		Globals.openWindowCount = Globals.openWindowCount + 1;
		eventCollector.addEvent(this, UIOEvent.REMOVED, onRemoved );
		eventCollector.addEvent( this, UIOEvent.RESIZED, onResized );
	}
	
	protected function onResized(e:UIOEvent):void 
	{
		trace( "VVContainer.onResize" );
		if ( _parent )
			_parent.onResized( e );
		//_barUpper.setButtonsWidth( width / _barUpper.length, 36 );
		//_underline.width = width;
	}
	
	protected function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeEvent(this, UIOEvent.REMOVED, onRemoved );
//		Globals.openWindowCount = Globals.openWindowCount - 1;
	}
	
}
}