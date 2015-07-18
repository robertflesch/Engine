/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI 
{
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.PermissionsModel;
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
	
	public function WindowModelMetadata( $ii:InstanceInfo, windowType:int )
	{
		_type = windowType;
		super("Model Metadata Detail");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, dataReceived );
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, dataReceived );
		
		// Only prompt for imports of parent models
		if ( TYPE_IMPORT == windowType ) {
			//_vmm = new ModelMetadata( $ii.modelGuid );
			_vmm = new ModelMetadata( $ii.modelGuid );
			var newDbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_METADATA, "0", "0", 0, true, null );
			newDbo.data = new Object();
			_vmm.fromObjectImport( newDbo );
			_vmm.name = $ii.modelGuid;
			_vmm.description = $ii.modelGuid + "-IMPORTED";
			_vmm.owner = Network.userId;
			// fake an event to populate the window
			dataReceived( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, Globals.getUID(), _vmm ) );
			
			if ( $ii.controllingModel ) {
				ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
				ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, $ii.controllingModel.modelInfo.guid, null ) );
			}
		}
		else {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, $ii.modelGuid, null ) );
		}
	}
	
	private function modelInfoResult(e:ModelInfoEvent):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
		var modelClass:String = e.vmi.modelClass;
		_vmm.animationClass = AnimationCache.requestAnimationClass( modelClass );
	}
	
	private function dataReceived( $mme:ModelMetadataEvent ):void {
		
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, dataReceived );
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, dataReceived );
		
		_vmm = $mme.modelMetadata;
		
		if ( TYPE_IMPORT == _type ) {
			var creatorI:LabelInput = new LabelInput( "Creator: ", _vmm.permissions.creator );
			creatorI.editable = false;
			creatorI.selectable = false;
			creatorI.enabled = false;
			addElement( creatorI );
			
			_name = new LabelInput( "Name: ", _vmm.name );
			addElement( _name );

			_desc = new LabelInput( "Description: ", _vmm.description );
			addElement( _desc );
		
		} else {
			var creator:LabelInput = new LabelInput( "Creator: ", _vmm.permissions.creator );
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
							   , { label:"Unique Instance" } );
			eventCollector.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _vmm.permissions.blueprint = (0 == event.target.index ?  true : false) } );
			rbGroup.dataProvider = radioButtons;
			rbGroup.index = 1;

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
			
Log.out( "WindowModelMetadata - need drop down list of Bind types", Log.WARN );			
			var rbTransferGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbTransferGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _vmm.permissions.binding = (0 == event.target.index ?  PermissionsModel.BIND_MODIFY :  PermissionsModel.BIND_NONE ) } );
			var rbTransferDP:DataProvider = new DataProvider();
			rbTransferDP.addAll( { label:"Allow this object to be transferred" }
							   , { label:"Bind this object to user" } );
			rbTransferGroup.dataProvider = rbTransferDP;
			rbTransferGroup.index = 0;
			
			addElement( new HorizontalSeparator( width ) );		
			
			var rbModifyGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbModifyGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _vmm.permissions.modify = (0 == event.target.index ?  true :  false ) } );
			var rbModifyDP:DataProvider = new DataProvider();
			rbModifyDP.addAll( { label:"Allow this object to be modified" }
							   , { label:"This objects shape is set" } );
			rbModifyGroup.dataProvider = rbModifyDP;
			rbModifyGroup.index = 0;

			addElement( new HorizontalSeparator( width ) );		
			
			var rbCopyGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbCopyGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _vmm.permissions.copyCount = (0 == event.target.index ?  -1 :  1 ) } );
			var rbCopyDP:DataProvider = new DataProvider();
			rbCopyDP.addAll( { label:"Allow this object to be copied freely" }
						   , { label:"Allow how many copies - below (1) min" } );
			rbCopyGroup.dataProvider = rbCopyDP;
			rbCopyGroup.index = 0;
			
			addElement( new HorizontalSeparator( width ) );
			
			_copies = new LabelInput( "Num of copies : ", "1" );
			_copies.labelControl.width = 40;
			addElement( _copies );
			
			addElement( new HorizontalSeparator( width ) );
		}
		
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
		if ( _type == TYPE_EDIT ) {
			// this field only exists when I am editting
			_vmm.permissions.copyCount = parseInt( _copies.label, 10 );
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.UPDATE, 0, _vmm.guid, _vmm ) );
		} else { // TYPE_IMPORT so new data
			ModelMetadataEvent.dispatch( new ModelMetadataEvent ( ModelBaseEvent.GENERATION, 0, _vmm.guid, _vmm ) );
		}
		remove();
	}
}
}