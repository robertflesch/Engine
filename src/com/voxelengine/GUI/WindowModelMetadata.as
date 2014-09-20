
package com.voxelengine.GUI 
{
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Persistance;
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
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;

import com.voxelengine.Globals;
import com.voxelengine.Log;

public class WindowModelMetadata extends VVPopup
{
	private var _guid:String;
	private var _name:LabelInput;
	private var _desc:LabelInput;
	private var _template:Boolean;
	private var _owner:String;
	private var _rbGroup:RadioButtonGroup = null;
	
	
	public function WindowModelMetadata( $guid:String )
	{
		super("Model Metadata Detail");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//_modalObj = new ModalObject( this );
		_guid = $guid
		
		_name = new LabelInput( "Name: ", $guid );
		addElement( _name );

		var rbGroup:RadioButtonGroup = new RadioButtonGroup( this );
		var radioButtons:DataProvider = new DataProvider();
		radioButtons.addAll( { label:"Template for other models" }
		                   , { label:"Unique Instance" } );
		eventCollector.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _template = (0 == event.target.index ?  true : false) } );
		rbGroup.dataProvider = radioButtons;
		rbGroup.index = 0;

		_desc = new LabelInput( "Description: ", $guid );
		addElement( _desc );
		
		var rbOwnerGroup:RadioButtonGroup = new RadioButtonGroup( this );
		var radioButtonsOwner:DataProvider = new DataProvider();
		radioButtonsOwner.addAll( { label:"Owned by " + Network.userId }
		                        , { label:"Public Object" } );
		eventCollector.addEvent( rbOwnerGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _owner = (0 == event.target.index ?  Network.userId :  Persistance.PUBLIC ) } );
		rbOwnerGroup.dataProvider = radioButtonsOwner;
		rbOwnerGroup.index = 0;
		
		var saveMetadata:Button = new Button( "Save" );
		eventCollector.addEvent( saveMetadata, UIMouseEvent.CLICK, save );
		addElement( saveMetadata );
		
		//var cancelButton:Button = new Button( "Cancel" );
		//eventCollector.addEvent( cancelButton , UIMouseEvent.CLICK
							   //, function( e:UIMouseEvent ):void { remove(); } );
		//addElement( cancelButton );

		eventCollector.addEvent( this, Event.RESIZE, onResize );
		eventCollector.addEvent( this, UIMouseEvent.CLICK, windowClick );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		eventCollector.addEvent( this, UIMouseEvent.PRESS, pressWindow );
		
		// This auto centers
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function save( e:UIMouseEvent ):void { 
		Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_COLLECTED, _name.label, _desc.label, _guid, _owner, _template ) );
		remove();
	}
	
	private function pressWindow(e:UIMouseEvent):void
	{
	}
	
	private function windowClick(e:UIMouseEvent):void
	{
	}
	
	protected function onResize(event:Event):void
	{
		move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
	}
	
	private function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeAllEvents();
	}
}
}