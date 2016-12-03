
package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.renderer.Renderer;

import flash.events.Event;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.SpasUI

import com.voxelengine.Globals
import com.voxelengine.GUI.VVPopup
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.models.makers.ModelMakerClone
import com.voxelengine.GUI.LanguageManager

	public class WindowBluePrintCopy extends VVPopup
	{
		static private var _instance:WindowBluePrintCopy
		static public function exists():Boolean { return null == _instance ? false : true }
		
		private var _vm:VoxelModel
		public function WindowBluePrintCopy( $vm:VoxelModel ) {
			_instance = this
			_vm = $vm
	
			super( "This is a Blue Print Model" ) //( "Would you like to create a copy of this blue print?", 350 );
			layout.orientation = LayoutOrientation.VERTICAL;
			autoSize = false
			padding = 5
			width = 250
			height = 100
			addButtonPanel()
			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
			
			
			Globals.g_app.stage.addEventListener(Event.RESIZE, onResizeHeading );
			addEventListener(UIOEvent.REMOVED, onRemoved );
		}
		
		protected function clone():void {
			new ModelMakerClone( _vm );
		}
		
	private function addButtonPanel():void {
		if ( 0 == _vm.metadata.permissions.copyCount ) {
			addElement( new Label( "You have no copies left to make of this object, and it is not editable", width - padding * 2 ) )
		}
		else {
			var saveAnimation:Button = new Button( LanguageManager.localizedStringGet( "Create copy of Blue Print" ))
			saveAnimation.addEventListener(UIMouseEvent.CLICK, saveHandler )
			saveAnimation.width = width - padding * 2
			saveAnimation.height = height/2 - padding
			addElement( saveAnimation )
		}
		
		var revert:Button = new Button( LanguageManager.localizedStringGet( "Dont create copy, do nothing" ))
		revert.autoSize = false
		revert.addEventListener(UIMouseEvent.CLICK, revertHandler )
		revert.width = width - padding * 2
		revert.height = height/2 - padding
		addElement( revert )
	}

	private function revertHandler(event:UIMouseEvent):void  {
		remove()
	}

	private  function saveHandler(event:UIMouseEvent):void  {
		
		clone()
		remove()
	}
	
	protected function onResizeHeading( event:Event ):void {
		move( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
	}

	// Window events
	private function onRemoved( event:UIOEvent ):void {
		_instance = null
		Globals.g_app.stage.removeEventListener(Event.RESIZE, onResizeHeading );
		removeEventListener(UIOEvent.REMOVED, onRemoved );
	}
}
}