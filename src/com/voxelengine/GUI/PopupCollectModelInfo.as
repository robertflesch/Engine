/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI 
{

import org.flashapi.swing.Button;
import org.flashapi.swing.HorizontalSeparator;
import org.flashapi.swing.constants.LayoutOrientation;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.GUI.components.VVLabelInput;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.PermissionsModel;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelInfo;

import org.flashapi.swing.event.ButtonsGroupEvent;
import org.flashapi.swing.event.UIMouseEvent;

public class PopupCollectModelInfo extends VVPopup
{
	private var _name:VVLabelInput;
	private var _desc:VVLabelInput;
	private var _hashTags:VVLabelInput;

	private var _copies:VVLabelInput;
	private var _mi:ModelInfo;
	private var _type:int;
	
	public static const TYPE_IMPORT:int = 0;
	public static const TYPE_EDIT:int = 1;
	
	public function PopupCollectModelInfo($ii:InstanceInfo, $mi:ModelInfo, windowType:int )
	{
		// This one will require some farther thought
		_type = windowType;
		super("Model Detail");
		_mi = $mi;
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;

		// Only prompt for imports of parent models
		if ( TYPE_IMPORT == windowType ) {
			_mi.description = $ii.modelGuid + "-IMPORTED";
			_mi.owner = Network.userId;

//			if ( $ii.controllingModel ) {
//				ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
//				ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, $ii.controllingModel.modelInfo.guid, null ) );
//			}
		}
		if ( _mi.modelClass )
        	_mi.animationClass = AnimationCache.requestAnimationClass( _mi.modelClass );

		if ( TYPE_IMPORT == _type ) {
			var creatorI:VVLabelInput = new VVLabelInput( "Creator: ", _mi.permissions.creator );
			creatorI.editable = false;
			creatorI.selectable = false;
			creatorI.enabled = false;
			addElement( creatorI );
			
			_name = new VVLabelInput( "Name: ", _mi.name );
			addElement( _name );

			_desc = new VVLabelInput( "Description: ", _mi.description );
			addElement( _desc );

			_hashTags = new VVLabelInput( "HashTags: ", "#imported" );
			addElement( _hashTags );

		} else {
			var creator:VVLabelInput = new VVLabelInput( "Creator: ", _mi.permissions.creator );
			creator.editable = false;
			creator.selectable = false;
			creator.enabled = false;
			addElement( creator );
			
			_name = new VVLabelInput( "Name: ", _mi.name );
			addElement( _name );

			_desc = new VVLabelInput( "Description: ", _mi.description );
			addElement( _desc );

			_hashTags = new VVLabelInput( "HashTags: ", _mi.hashTags );
			addElement( _hashTags );

			addElement( new HorizontalSeparator( width ) );
			
			addElement( new HorizontalSeparator( width ) );
			
			var rbOwnerGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbOwnerGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _mi.owner = (0 == event.target.index ?  Network.userId :  Network.PUBLIC ) } );
			var radioButtonsOwner:DataProvider = new DataProvider();
			radioButtonsOwner.addAll( { label:"Owned by " + Network.userId }
									, { label:"Public Object" } );
			rbOwnerGroup.dataProvider = radioButtonsOwner;
			rbOwnerGroup.index = 0;
			
			addElement( new HorizontalSeparator( width ) );		
			
Log.out( "PopupCollectModelInfo - need drop down list of Bind types", Log.WARN );
			var rbTransferGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbTransferGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _mi.permissions.binding = (0 == event.target.index ?  PermissionsModel.BIND_MODIFY :  PermissionsModel.BIND_NONE ) } );
			var rbTransferDP:DataProvider = new DataProvider();
			rbTransferDP.addAll( { label:"Allow this object to be transferred" }
							   , { label:"Bind this object to user" } );
			rbTransferGroup.dataProvider = rbTransferDP;
			rbTransferGroup.index = 0;
			
			addElement( new HorizontalSeparator( width ) );		
			
Log.out( "PopupCollectModelInfo.dataReceived - NOT SHOWING MODIFY OPTIONS", Log.WARN);
//			var rbModifyGroup:RadioButtonGroup = new RadioButtonGroup( this );
//			eventCollector.addEvent( rbModifyGroup, ButtonsGroupEvent.GROUP_CHANGED
//								   , function (event:ButtonsGroupEvent):void {  _mi.permissions.modify = (0 == event.target.index ?  true :  false ) } );
//			var rbModifyDP:DataProvider = new DataProvider();
//			rbModifyDP.addAll( { label:"Allow this object to be modified" }
//							   , { label:"This objects shape is set" } );
//			rbModifyGroup.dataProvider = rbModifyDP;
//			rbModifyGroup.index = 0;

			addElement( new HorizontalSeparator( width ) );		
			
			var rbCopyGroup:RadioButtonGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( rbCopyGroup, ButtonsGroupEvent.GROUP_CHANGED
								   , function (event:ButtonsGroupEvent):void {  _mi.permissions.copyCount = (0 == event.target.index ?  -1 :  1 ) } );
			var rbCopyDP:DataProvider = new DataProvider();
			rbCopyDP.addAll( { label:"Allow this object to be copied freely" }
						   , { label:"Allow how many copies - below (1) min" } );
			rbCopyGroup.dataProvider = rbCopyDP;
			rbCopyGroup.index = 0;
			
			addElement( new HorizontalSeparator( width ) );
			
			_copies = new VVLabelInput( "Num of copies : ", "1" );
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
		display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function save( e:UIMouseEvent ):void { 
		_mi.name 		= _name.label;
		_mi.description = _desc.label;
        _mi.hashTags 	= _hashTags.label;
		if ( _type == TYPE_EDIT ) {
			// this field only exists when I am editting
			_mi.permissions.copyCount = parseInt( _copies.label, 10 );
		} else { // TYPE_IMPORT so new data
            ModelInfoEvent.create( ModelInfoEvent.DATA_COLLECTED, 0, _mi.guid, _mi );
		}
		remove();
	}
}
}