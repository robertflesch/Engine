
package com.voxelengine.GUI 
{
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
import com.voxelengine.events.AnimationMetadataEvent;
import com.voxelengine.server.Network;

public class WindowAnimationMetadata extends VVPopup
{
	private var _guid:String;
	private var _owner:String;
	private var _name:String;
	private var _desc:LabelInput;
	private var _animCombo:ComboBox
	
	public function WindowAnimationMetadata( $ownerGuid:String )
	{
		super("Animation Details");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		_owner = $ownerGuid
		_guid = Globals.getUID();
		
		_animCombo = new ComboBox( "Available Animations" );
		_animCombo.addEventListener(ListEvent.ITEM_CLICKED, animationSelected );
		
		var dp:DataProvider = new DataProvider();
		dp.addAll(  { label:"Fly" },
					{ label:"Glide" },
					{ label:"Land" },
					{ label:"Dive" },
					{ label:"Walk" } );
		_animCombo.dataProvider = dp;
		addElement( _animCombo );

		_desc = new LabelInput( "Description: ", $ownerGuid );
		addElement( _desc );
		
		var saveMetadata:Button = new Button( "Save" );
		eventCollector.addEvent( saveMetadata, UIMouseEvent.CLICK, save );
		addElement( saveMetadata );
		
		var cancelButton:Button = new Button( "Cancel" );
		eventCollector.addEvent( cancelButton , UIMouseEvent.CLICK
							   , function( e:UIMouseEvent ):void { remove(); } );
		addElement( cancelButton );

		// This auto centers
		display();
		onResize( null );
	}
	
	private function animationSelected( e:ListEvent ):void { 
		var li:ListItem = _animCombo.getItemAt( _animCombo.selectedIndex );
		_name = li.value;
	}
	
	private function save( e:UIMouseEvent ):void { 
		Globals.g_app.dispatchEvent( new AnimationMetadataEvent( AnimationMetadataEvent.ANIMATION_INFO_COLLECTED, _name, _desc.label, _guid, Network.PUBLIC ) );
		remove();
	}
}
}