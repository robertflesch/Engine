/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI 
{
import com.voxelengine.events.PersistanceEvent;
import flash.events.Event;
import playerio.DatabaseObject;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
//import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.constants.LayoutOrientation;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.ModelMetadataCache;
import com.voxelengine.worldmodel.models.ModelMetadata;

public class WindowModelMetadata extends VVPopup
{
	private var _name:LabelInput;
	private var _desc:LabelInput;
	private var _copies:LabelInput;
	private var _vmm:ModelMetadata;
	private var _type:int;
	
	public static const TYPE_IMPORT:int = 0;
	public static const TYPE_EDIT:int = 1;
	
	public function WindowModelMetadata( $guid:String, windowType:int )
	{
		_type = windowType;
		super("Model Metadata Detail");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, dataReceived );
		
		if ( TYPE_IMPORT == windowType ) {
			_vmm = new ModelMetadata( $guid );
			_vmm.name = $guid + "-IMPORTED";
			_vmm.description = $guid + "-IMPORTED";
			_vmm.creator = "simpleBob";
			// fake an event to populate the window
			dataReceived( new ModelMetadataEvent( ModelBaseEvent.REQUEST, $guid, _vmm ) )
		}
		else {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, $guid, null ) );
		}
	}
	
	private function dataReceived( $mme:ModelMetadataEvent ):void {
		
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, dataReceived );
		
		_vmm = $mme.vmm;
		
		var creator:LabelInput = new LabelInput( "Creator: ", _vmm.creator );
		creator.editable = false;
		creator.selectable = false;
		creator.enabled = false;
		addElement( creator );
		
		_name = new LabelInput( "Name: ", _vmm.name );
		addElement( _name );

		_desc = new LabelInput( "Description: ", _vmm.description );
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
		rbTransferDP.addAll( { label:"Allow this object to be transferred" }
		                   , { label:"Bind this object to user" } );
		rbTransferGroup.dataProvider = rbTransferDP;
		rbTransferGroup.index = 0;
		
		addElement( new HorizontalSeparator( width ) );		
		
		var rbModifyGroup:RadioButtonGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( rbModifyGroup, ButtonsGroupEvent.GROUP_CHANGED
		                       , function (event:ButtonsGroupEvent):void {  _vmm.modify = (0 == event.target.index ?  true :  false ) } );
		var rbModifyDP:DataProvider = new DataProvider();
		rbModifyDP.addAll( { label:"Allow this object to be modified" }
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
		
		_copies = new LabelInput( "Num of copies(-1 = infinite): ", "-1" );
		_copies.labelControl.width = 40;
		addElement( _copies );
		
		addElement( new HorizontalSeparator( width ) );
		
		var saveMetadata:Button = new Button( "Save" );
		eventCollector.addEvent( saveMetadata, UIMouseEvent.CLICK, save );
		addElement( saveMetadata );
		
		//var cancelButton:Button = new Button( "Cancel" );
		//eventCollector.addEvent( cancelButton , UIMouseEvent.CLICK
							   //, function( e:UIMouseEvent ):void { remove(); } );
		//addElement( cancelButton );

		// This auto centers
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function save( e:UIMouseEvent ):void { 
		_vmm.name = _name.label;
		_vmm.description = _desc.label;
		_vmm.copyCount = parseInt( _copies.label, 10 );
		_vmm.createdDate = new Date();
		_vmm.modifiedDate = new Date();
		if ( _type == TYPE_EDIT ) {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.UPDATE, _vmm.guid, _vmm ) );
		} else { // TYPE_IMPORT so new data
			var dboTemp:DatabaseObject = new DatabaseObject( Globals.DB_TABLE_MODELS, _vmm.guid, "1", 0, true, null );
			_vmm.dbo = dboTemp;
			_vmm.toPersistance();
			_vmm.dbo = null;
			_vmm.release();
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, Globals.DB_TABLE_MODELS, _vmm.guid, dboTemp, true ) );			
		}
		remove();
	}
	
			//var dboTemp:DatabaseObject = new DatabaseObject( Globals.DB_TABLE_REGIONS, _region.guid, "1", 0, true, null );
			//_region.dbo = dboTemp;
			//_region.toPersistance();
			//// remove the event listeners on this temporary object
			//_region.release();
			//// This tell the region manager to add it to the region list
			//PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, Globals.DB_TABLE_REGIONS, _region.guid, dboTemp, true ) );			
			//// This tell the region to save itself!
			//RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, _region.guid ) );
	//
}
}