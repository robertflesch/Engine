
package com.voxelengine.GUI 
{
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.VoxelModelMetadata;
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
	private var _name:LabelInput;
	private var _desc:LabelInput;
	private var _copies:LabelInput;
	private var _vmm:VoxelModelMetadata;
	
	public function WindowModelMetadata( $guid:String )
	{
		_vmm = new VoxelModelMetadata();
		super("Model Metadata Detail");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;

		_vmm.guid = $guid
		
		_name = new LabelInput( "Name: ", $guid );
		addElement( _name );

		_desc = new LabelInput( "Description: ", $guid );
		addElement( _desc );
		
		addElement( new HorizontalSeparator( width ) );		
		
		var rbGroup:RadioButtonGroup = new RadioButtonGroup( this );
		var radioButtons:DataProvider = new DataProvider();
		radioButtons.addAll( { label:"Template for other models" }
		                   , { label:"Unique Instance (careful here)" } );
		eventCollector.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.template = (0 == event.target.index ?  true : false) } );
		rbGroup.dataProvider = radioButtons;
		rbGroup.index = 0;

		addElement( new HorizontalSeparator( width ) );		
		
		var rbOwnerGroup:RadioButtonGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( rbOwnerGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.owner = (0 == event.target.index ?  Network.userId :  Network.PUBLIC ) } );
		var radioButtonsOwner:DataProvider = new DataProvider();
		radioButtonsOwner.addAll( { label:"Owned by " + Network.userId }
		                        , { label:"Public Object" } );
		rbOwnerGroup.dataProvider = radioButtonsOwner;
		rbOwnerGroup.index = 0;
		
		addElement( new HorizontalSeparator( width ) );		
		
		var rbTransferGroup:RadioButtonGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( rbTransferGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.transfer = (0 == event.target.index ?  true :  false ) } );
		var rbTransferDP:DataProvider = new DataProvider();
		rbTransferDP.addAll( { label:"All this object to be transferred" }
		                   , { label:"Bind this object to user" } );
		rbTransferGroup.dataProvider = rbTransferDP;
		rbTransferGroup.index = 0;
		
		addElement( new HorizontalSeparator( width ) );		
		
		var rbModifyGroup:RadioButtonGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( rbModifyGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.modify = (0 == event.target.index ?  true :  false ) } );
		var rbModifyDP:DataProvider = new DataProvider();
		rbModifyDP.addAll( { label:"All this object to be modified" }
		                   , { label:"This objects shape is set" } );
		rbModifyGroup.dataProvider = rbModifyDP;
		rbModifyGroup.index = 0;

		addElement( new HorizontalSeparator( width ) );		
		
		var rbCopyGroup:RadioButtonGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( rbCopyGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.copy = (0 == event.target.index ?  true :  false ) } );
		var rbCopyDP:DataProvider = new DataProvider();
		rbCopyDP.addAll( { label:"Allow this object to be copied freely" }
		               , { label:"Allow how many copies - below (1) min" } );
		rbCopyGroup.dataProvider = rbCopyDP;
		rbCopyGroup.index = 0;
		
		addElement( new HorizontalSeparator( width ) );
		
		_copies = new LabelInput( "Num of copies: ", "1" );
		addElement( _copies );
		
		addElement( new HorizontalSeparator( width ) );
		
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
		_vmm.name = _name.label;
		_vmm.description = _desc.label;
		_vmm.copyCount = parseInt( _copies.label, 10 );
		Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_COLLECTED, _vmm ) );
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