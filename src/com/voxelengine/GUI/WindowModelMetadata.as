
package com.voxelengine.GUI 
{
import com.voxelengine.events.ModelMetadataEvent;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import flash.events.Event;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.dnd.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;

public class WindowModelMetadata extends VVPopup
{
//	private var _loadFileButton:Button;
//	private var _saveFileButton:Button;
	
	private var _name:LabelInput
	private var _desc:LabelInput
	
	public function WindowModelMetadata( $fileName:String )
	{
		super("Model Metadata Detail");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//_modalObj = new ModalObject( this );
		
		_name = new LabelInput( "Name: ", $fileName );
		addElement( _name );
		_desc = new LabelInput( "Description: ", $fileName );
		addElement( _desc );
		
		var saveMetadata:Button = new Button( "Save" );
		eventCollector.addEvent( saveMetadata, UIMouseEvent.CLICK
							   , function( e:UIMouseEvent ):void { Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_COLLECTED, _name.label, _desc.label ) ); remove(); } );
		addElement( saveMetadata );
		
		var cancelButton:Button = new Button( "Cancel" );
		eventCollector.addEvent( cancelButton , UIMouseEvent.CLICK
							   , function( e:UIMouseEvent ):void { remove(); } );
		addElement( cancelButton );

		eventCollector.addEvent( this, Event.RESIZE, onResize );
		eventCollector.addEvent( this, UIMouseEvent.CLICK, windowClick );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		eventCollector.addEvent( this, UIMouseEvent.PRESS, pressWindow );
		
		// This auto centers
		//_modalObj.display();
		// this does not...
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
		//display();
	}
	
	private function pressWindow(e:UIMouseEvent):void
	{
	}
	
	private function windowClick(e:UIMouseEvent):void
	{
	}
	
	protected function onResize(event:Event):void
	{
		//Globals.GUIControl = true;
		move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
	}
	
	private function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeAllEvents();
	}
}
}