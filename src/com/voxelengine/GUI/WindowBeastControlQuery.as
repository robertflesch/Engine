
package com.voxelengine.GUI
{
	import com.voxelengine.events.ModelEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.GUIEvent;
	import com.voxelengine.worldmodel.models.types.Ship;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.RegionManager;
	
public class WindowBeastControlQuery extends VVCanvas
	{
		static private var _s_currentInstance:WindowBeastControlQuery = null;
		static public function get currentInstance():WindowBeastControlQuery { return _s_currentInstance; }
		
		private var _beastInstanceGuid:String = "";
		private const TOOL_BAR_HEIGHT:int = 140;
		private var window_offset:int = TOOL_BAR_HEIGHT;
		
		
		static public function handleModelEvents( $me:ModelEvent ):void {
			if ( ModelEvent.TAKE_CONTROL == $me.type ) {
				if ( WindowBeastControlQuery.currentInstance )
					WindowBeastControlQuery.currentInstance.remove();
			}
		}
		
		public function WindowBeastControlQuery( $beastInstanceGuid:String ):void 
		{ 
			super();
			if ( null != WindowBeastControlQuery.currentInstance )
				Log.out( "WindowBeastControlQuery.constructor - trying to create window when one already exists" );
				
			_beastInstanceGuid = $beastInstanceGuid;
			_s_currentInstance = this;
			autoSize = true;
			
			var button:Button = new Button( "Click me to control beast ( or 'F' key )" );
			button.width = 300;
			button.height = 80;
			button.addEventListener(MouseEvent.CLICK, takeControlMouse );
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, takeControlKey );
			addElement( button );
			
            Globals.g_app.stage.addEventListener(Event.RESIZE, onResize );
			RegionEvent.addListener( RegionEvent.UNLOAD, onRegionUnload );
			GUIEvent.addListener( GUIEvent.TOOLBAR_HIDE, guiEventHandler );
			GUIEvent.addListener( GUIEvent.TOOLBAR_SHOW, guiEventHandler );
			addEventListener(UIOEvent.REMOVED, onRemoved );
				
			display();
			onResize( null );
		} 
		
        protected function onResize( event:Event ):void
        {
			move( Globals.g_renderer.width / 2 - width / 2, Globals.g_renderer.height - height - window_offset );
		}
		
		private function onRegionUnload ( le:RegionEvent ):void 
		{ 
			remove();
		}
		

		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
			removeEventListener(UIOEvent.REMOVED, onRemoved );
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize );
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, takeControlKey );
			RegionEvent.removeListener( RegionEvent.UNLOAD, onRegionUnload );
			GUIEvent.removeListener( GUIEvent.TOOLBAR_HIDE, guiEventHandler );
			GUIEvent.removeListener( GUIEvent.TOOLBAR_SHOW, guiEventHandler );
			_s_currentInstance = null;
		}

		private function takeControl():void 
		{
			var vm:VoxelModel = Globals.modelGet( _beastInstanceGuid );
			if ( vm )
			{
				remove();
				vm.takeControl( Globals.player );
			}
		}
		
		private function takeControlKey(e:KeyboardEvent):void 
		{
			if ( Keyboard.F == e.keyCode )
				takeControl();
		}
		
		private function takeControlMouse(event:UIMouseEvent):void 
		{
			event.target.removeEventListener(MouseEvent.CLICK, takeControl );
			takeControl();
		}
		
		private function guiEventHandler( e:GUIEvent ):void
		{
			if ( GUIEvent.TOOLBAR_HIDE == e.type )
				window_offset = 0;
			else if ( GUIEvent.TOOLBAR_SHOW == e.type )
				window_offset = TOOL_BAR_HEIGHT;
				
			onResize( null );
		}
	}
}