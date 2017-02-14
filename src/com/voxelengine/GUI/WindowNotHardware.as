/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI
{
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
import com.voxelengine.renderer.Renderer;

import flash.events.Event;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
	
	
	public class WindowNotHardware extends VVPopup
	{
		static private var _s_currentInstance:WindowNotHardware = null;
		static public function get currentInstance():WindowNotHardware { return _s_currentInstance; }

        private var _textArea:TextArea = new TextArea();
        private var _image:Image = null;
		
		public function WindowNotHardware( title:String, data:String ):void 
		{ 
			super( "No hardware accelleration Detected" );
            //autoSize = true;
			width = 300;
			height = 300;
			var _textArea:TextArea = new TextArea();
			_textArea.text = data;
			_textArea.fontSize = 24;
			_textArea.autoSize = true;
			_textArea.editable = false;
			_textArea.width = 300;
			_textArea.height = 300;
			
            addElement(_textArea);
			
			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );

			Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
			addEventListener(UIOEvent.REMOVED, onRemoved );
		}
	}
}