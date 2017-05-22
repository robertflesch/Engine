/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.GUI.actionBars.WindowBombControl;
import com.voxelengine.GUI.actionBars.WindowGunControl;
import com.voxelengine.GUI.actionBars.WindowShipControl;
import com.voxelengine.Log;
	import com.voxelengine.Globals;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.types.Ship;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.events.Event;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	public class WindowShipControlSimple extends VVCanvas
	{
		static private var _s_currentInstance:WindowShipControlSimple = null;
		static public function get currentInstance():WindowShipControlSimple { return _s_currentInstance; }
		static private var _lastRotation:Number = 0;
		
		private var _ship:Ship;
		private var fudgeFactor:int = 20;


		public function WindowShipControlSimple( vm:Ship ):void 
		{ 
			super();
			_s_currentInstance = this;
			_ship = vm;
			autoSize = true;
			padding = 10;
			layout.orientation = LayoutOrientation.VERTICAL;
			layout.horizontalAlignment = LayoutHorizontalAlignment.CENTER;
			
			var pc:Container = new Container();
			//onCloseFunction = closeFunction;
			//defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
			pc.layout.orientation = LayoutOrientation.HORIZONTAL;

			display( Renderer.renderer.width/2 - (width + fudgeFactor)/2, Renderer.renderer.height - height - 128 );
            Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
			addEventListener(UIOEvent.REMOVED, onRemoved );
			
			_ship.takeControl( VoxelModel.controlledModel );
		} 
		
		private function loseControl(event:UIMouseEvent):void 
		{
			if ( WindowShipControl.currentInstance )
			{
				WindowShipControl.currentInstance.remove();
			}
			if ( WindowGunControl.currentInstance )
			{
				WindowGunControl.currentInstance.remove();
			}
			if ( CanvasHeading.currentInstance )
			{
				CanvasHeading.currentInstance.remove();
			}
			if ( WindowBombControl.currentInstance )
			{
				WindowBombControl.currentInstance.remove();
			}

			remove();

			_ship.loseControl( VoxelModel.controlledModel );
		}
		
		private function onFileLoadError(event:Event):void
		{
			Log.out("WindowShipControl.onFileLoadError - File load error: " + event, Log.ERROR );
		}		

		
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize);
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			
			_s_currentInstance = null;
			VoxelModel.controlledModel.instanceInfo.controllingModel = null;
			if ( _ship )
				_ship.loseControl(VoxelModel.controlledModel);
		}
		
        protected function onResize(event:Event):void
        {
			move( Renderer.renderer.width / 2 - (width + fudgeFactor) / 2, Renderer.renderer.height - height - 128 );
		}
	}
}