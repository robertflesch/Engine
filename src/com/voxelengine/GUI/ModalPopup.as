
package com.voxelengine.GUI
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Globals;

public class ModalPopup extends Popup
{
	protected var _modalObj:ModalObject;
	
	public function ModalPopup( $title:String, $width:int = undefined, $height:int = undefined ):void
	{
		super( $title, $width, $height );
		Globals.openWindowCount = Globals.openWindowCount + 1;
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}
	
	protected function onRemoved( event:UIOEvent ):void
	{
		Globals.openWindowCount = Globals.openWindowCount - 1;
	}
}
}
