/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
	import org.flashapi.swing.event.UIOEvent;
	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*;
    import org.flashapi.swing.managers.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.server.WindowLogin;
	
	public class WindowHelp extends Popup
	{
        private var _textArea:TextArea = new TextArea();
		
		public function WindowHelp()
		{
            //_image = new Image("my_picture.jpg", 300, 326);
			
			super("Help");
            //autoSize = true;
			width = 600;
			height = 600;
			shadow = true;
			_textArea.width = 600;
			_textArea.height = 600;
			_textArea.editable = false;
			_textArea.loadText( Globals.appPath + "assets/help.txt" );
            addElement(_textArea);
			eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
			display(30, 30);
        }

		private function onRemoved( event:UIOEvent ):void {
			new WindowLogin( "", "" )
		}
		
	}
}