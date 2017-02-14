/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.renderer.Renderer;

import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
	import flash.events.Event;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	public class WindowQuest extends VVPopup
	{
		//private var eventCollector:EventCollector = new EventCollector();
		
		public function WindowQuest( title:String, data:String, x:int = 0, y:int = 0 )
		{
			super(title);
            //autoSize = true;
			width = 300;
			height = 300;
			var _textArea:TextArea = new TextArea();
			_textArea.loadText( Globals.appPath + data );
			_textArea.fontSize = 16;
			_textArea.autoSize = true;
			_textArea.editable = false;
			_textArea.width = 300;
			_textArea.height = 300;
            addElement(_textArea);
			
			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );

			Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
			addEventListener(UIOEvent.REMOVED, onRemoved );
		}

			
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize);
			removeEventListener(UIOEvent.REMOVED, onRemoved );
		}
		
        override protected function onResize(event:Event):void
        {
			move( Renderer.renderer.width / 2 - (width + 10) / 2, Renderer.renderer.height / 2 - (height + 10) / 2 );
		}
	}
}