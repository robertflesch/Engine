
package com.voxelengine.GUI
{
import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.Container;

import com.voxelengine.Globals;

public class VVContainer extends Container
{
	public function VVContainer($width:Number = 100, $height:Number = 100):void 
	{ 
		super($width,$height);
//		Globals.openWindowCount = Globals.openWindowCount + 1;
		eventCollector.addEvent(this, UIOEvent.REMOVED, onRemoved );
	}
	
	private function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeEvent(this, UIOEvent.REMOVED, onRemoved );
//		Globals.openWindowCount = Globals.openWindowCount - 1;
	}
	
}
}