/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.animation
{
import com.voxelengine.GUI.components.*;
import com.voxelengine.GUI.panels.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.animation.AnimationTransform;
import flash.geom.Vector3D;
import flash.net.FileReference;
import flash.events.Event;
import flash.net.FileFilter;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;


import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.ModelMetadata;

public class WindowAnimationDetail extends VVPopup
{
	private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 30;
	private var _modelKey:String;
	private static const WIDTH:int = 400;
	private var _ani:Animation;
	private var _create:Boolean;
	
	public function WindowAnimationDetail( $guid:String, $ani:Animation )
	{
		var title:String;
		if ( $ani ) 	title = LanguageManager.localizedStringGet( "Edit_Animation" );
		else			title = LanguageManager.localizedStringGet( "New_Animation" );
		super( title );	
		width = WIDTH;
	
		if ( $ani ) {
			_ani = $ani;
		}
		else {
			_create = true
			_ani = new Animation( "INVALID" );
		}
		
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		addMetadataPanel();
		addAnimationsPanel();
		addSoundPanel();
		//addAttachmentPanel();
		addButtonPanel();
		
		display();
	}
	
	private function addButtonPanel():void {
		var panelParentButton:Panel = new Panel( width, _TOTAL_BUTTON_PANEL_HEIGHT );
		panelParentButton.layout.orientation = LayoutOrientation.VERTICAL;
		panelParentButton.padding = 2;
		addElement( panelParentButton );
		
		var saveAnimation:Button = new Button( LanguageManager.localizedStringGet( "Save_Animation" ));
		saveAnimation.addEventListener(UIMouseEvent.CLICK, saveAnimationHandler );
		//saveAnimation.width = pbWidth - 2 * pbPadding;
		panelParentButton.addElement( saveAnimation );
	}

	private function saveAnimationHandler(event:UIMouseEvent):void  {
		// TODO FIXME
		// all changes are automattically saved, that is bad...
	}
	
	private function addMetadataPanel():void {
		addElement( new ComponentSpacer( width ) );
		addElement( new ComponentTextInput( "Name"
										  , function ($e:TextEvent):void { _ani.name = $e.target.text; setChanged(); }
										  , _ani.name ? _ani.name : "No Name"
										  , width ) );
		addElement( new ComponentTextArea( "Desc"
										 , function ($e:TextEvent):void { _ani.description = $e.target.text; setChanged(); }
										 , _ani.description ? _ani.description : "No Description"
										 , width ) );
		addElement( new ComponentLabel( "AnimationClass", _ani.animationClass, width ) );
		addElement( new ComponentLabel( "Type", _ani.type, width ) );
		
	}
	
	private function setChanged():void {
		_ani.changed = true;
	}
	
	private function addAnimationsPanel():void {
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.title = "transforms"
		ebco.width = WIDTH
		ebco.rootObject = _ani
		ebco.items = _ani.transforms as Vector.<*>
		ebco.itemDisplayObject = PanelAnimationTransform
		ebco.itemBox.showNew = false
		ebco.itemBox.title = "animatable elements"
		ebco.paddingTop = 8
		addElement( new PanelVectorContainer( null, ebco ) )
	}
	
	private function addSoundPanel():void {
		addElement( new PanelAnimationSound( _ani, WIDTH ) );
	}
/*	
	private function addAttachmentPanel():void {
		const showNewItem:Boolean = true;
		addElement( new PanelVectorContainer( "Attachments to be used"
											, _ani
		                                    , _ani.attachments as Vector.<*>
											, PanelAnimationAttachment
											, "Add a new attachment"
											, WIDTH
											, showNewItem ) );
	}
	*/
}
}