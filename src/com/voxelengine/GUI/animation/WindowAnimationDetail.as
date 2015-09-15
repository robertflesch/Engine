/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.animation
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
//import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.plaf.spas.SpasUI;

import com.voxelengine.Log;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.components.*;
import com.voxelengine.GUI.panels.*;
import com.voxelengine.worldmodel.animation.Animation;

public class WindowAnimationDetail extends VVPopup
{
	private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 30;
	private var _modelKey:String;
	private static const WIDTH:int = 400;
	private var _ani:Animation;
	private var _aniBackup:Animation;
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
		_aniBackup = _ani.clone( _ani.guid );
		
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		addMetadataPanel();
		addAnimationsPanel();
		addSoundPanel();
		//addAttachmentPanel();
		addButtonPanel();
		
		display();
		defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
		onCloseFunction = closeFunction;
	}
	
	private function closeFunction():void {
		// ask about saving changes?
		if ( _ani.changed ) 
			queryToSaveChanges()
		remove();
		
		function queryToSaveChanges():void {
			var alert:Alert = new Alert( "You have unsaved changes, want do you want to do?", 400 )
			alert.setLabels( "Save", "Abandon" );
			alert.alertMode = AlertMode.CHOICE;
			$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
			alert.display();
			
			function alertAction( $ae:AlertEvent ):void {
				if ( AlertEvent.ACTION == $ae.action )
					_ani.save()
				else ( AlertEvent.CHOICE == $ae.action )
					_ani = _aniBackup
			}
		}
	}
	
	private function addButtonPanel():void {
		var buttonBox:Box = new Box( width, 35, BorderStyle.NONE )
		buttonBox.layout.orientation = LayoutOrientation.HORIZONTAL
		buttonBox.backgroundColor = SpasUI.DEFAULT_COLOR
		buttonBox.padding = 2
		addElement( buttonBox )
		
		var saveAnimation:Button = new Button( LanguageManager.localizedStringGet( "Save_Animation" ));
		saveAnimation.addEventListener(UIMouseEvent.CLICK, saveHandler );
		//saveAnimation.width = pbWidth - 2 * pbPadding;
		buttonBox.addElement( saveAnimation );
		
		var revert:Button = new Button( LanguageManager.localizedStringGet( "Revert Changes" ));
		revert.addEventListener(UIMouseEvent.CLICK, revertHandler );
		//revert.width = pbWidth - 2 * pbPadding;
		buttonBox.addElement( revert );
		
		function revertHandler(event:UIMouseEvent):void  {
			_ani = _aniBackup
		}
		function saveHandler(event:UIMouseEvent):void  {
			_ani.save()
		}
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