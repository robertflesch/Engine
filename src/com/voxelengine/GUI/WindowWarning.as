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
	
	public class WindowWarning extends VVCanvas
	{
		static private var _s_currentInstance:WindowWarning = null;
		static public function get currentInstance():WindowWarning { return _s_currentInstance; }

		public function WindowWarning():void 
		{ 
			super();
			_s_currentInstance = this;

			var warning:Text = new Text( 600, 100 );
			warning.text = "Alpha Demo";
			warning.fontSize = 24;
			warning.fontColor = 0xffffff;
			warning.alpha = 0.5;
			addElement( warning );
			
			autoSize = false;
			shadow = true;
			
			display( Renderer.renderer.width / 2 - 300, 60 );
			
            Globals.g_app.stage.addEventListener(Event.RESIZE, onResizeHeading );
			addEventListener(UIOEvent.REMOVED, onRemoved );
		} 
		
        protected function onResizeHeading( event:Event ):void
        {
			move( Renderer.renderer.width / 2 - 300, 60 );
		}

		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResizeHeading );
			removeEventListener(UIOEvent.REMOVED, onRemoved );
		}
	}
}