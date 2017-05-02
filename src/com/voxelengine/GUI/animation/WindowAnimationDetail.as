/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.animation
{
import com.voxelengine.worldmodel.models.types.VoxelModel
import org.flashapi.swing.*
import org.flashapi.swing.event.*
import org.flashapi.swing.constants.*
import org.flashapi.swing.plaf.spas.VVUI;

import com.voxelengine.Log
import com.voxelengine.GUI.VVPopup
import com.voxelengine.GUI.LanguageManager
import com.voxelengine.GUI.components.*
import com.voxelengine.GUI.panels.*
import com.voxelengine.worldmodel.animation.Animation

public class WindowAnimationDetail extends VVPopup
{
	private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 30
	private var _modelKey:String
	private static const WIDTH:int = 400
	private var _ani:Animation
	private var _infoBackup:Object
	private var _create:Boolean
	
	public function WindowAnimationDetail( $guid:String, $ani:Animation )
	{
		var title:String
		if ( $ani ) 	title = LanguageManager.localizedStringGet( "Edit_Animation" )
		else			title = LanguageManager.localizedStringGet( "New_Animation" )
		super( title )	
		autoSize = false
		autoHeight = true
		width = WIDTH
	
		if ( $ani ) {
			_ani = $ani
		}
		else {
			_create = true
			throw new Error( "WindowAnimationDetail - What to do here?");
//			_ani = Animation.defaultObject( $guid )
		}
		_infoBackup = _ani.createBackCopy()
		_ani.doNotPersist = true // true while editing
		
		layout.orientation = LayoutOrientation.VERTICAL
		padding = 5
		addMetadataPanel()
		addAnimationsPanel()
		addSoundPanel()
		//addAttachmentPanel()
		addButtonPanel()
		
		display()
		defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION
		onCloseFunction = closeFunction
	}
	
	private function closeFunction():void {
		// ask about saving changes?
		if ( _ani.changed ) 
			queryToSaveChanges()
			
		remove()
		
		function queryToSaveChanges():void {
			var alert:Alert = new Alert( "You have unsaved changes, want do you want to do?", 400 );
			alert.setLabels( "Save", "Abandon" )
			alert.alertMode = AlertMode.CHOICE
			$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
			alert.display()
			
			function alertAction( $ae:AlertEvent ):void {
				if ( AlertEvent.ACTION == $ae.action ) {
					saveHandler( null )
				}
				else ( AlertEvent.CHOICE == $ae.action )
					revertHandler( null )
			}
		}
	}
	
	private function addButtonPanel():void {
		var buttonBox:Box = new Box( width, 35, BorderStyle.NONE );
		buttonBox.layout.orientation = LayoutOrientation.HORIZONTAL;
		buttonBox.backgroundColor = VVUI.DEFAULT_COLOR;
		buttonBox.padding = 2;
		addElement( buttonBox );
		
		const BUTTON_COUNT:int = 2;
		var saveAnimation:Button = new Button( LanguageManager.localizedStringGet( "Save" ));
		saveAnimation.addEventListener(UIMouseEvent.CLICK, saveHandler );
		saveAnimation.width = buttonBox.width/BUTTON_COUNT - buttonBox.padding * BUTTON_COUNT;
		buttonBox.addElement( saveAnimation );
		
		//var apply:Button = new Button( LanguageManager.localizedStringGet( "Apply" ))
		//apply.addEventListener(UIMouseEvent.CLICK, applyHandler )
		//apply.width = buttonBox.width/BUTTON_COUNT - buttonBox.padding * BUTTON_COUNT
		//buttonBox.addElement( apply )
		
		var revert:Button = new Button( LanguageManager.localizedStringGet( "Revert" ));
		revert.addEventListener(UIMouseEvent.CLICK, revertHandler );
		revert.width = buttonBox.width/BUTTON_COUNT - buttonBox.padding * BUTTON_COUNT;
		buttonBox.addElement( revert )
	}
	
	private function revertHandler(event:UIMouseEvent):void  {
		_ani.restoreFromBackup( _infoBackup )
		_ani.doNotPersist = false
		_ani.changed = false
		remove()
	}
	
	//private function applyHandler(event:UIMouseEvent):void  {
		//VoxelModel.selectedModel.stateLock( false )
		//VoxelModel.selectedModel.stateSet( "Starting", 0 )
		//VoxelModel.selectedModel.stateSet( _ani.name, 0 )
		//VoxelModel.selectedModel.stateLock( true )
		//
	//}

	private  function saveHandler(event:UIMouseEvent):void  {
		_ani.doNotPersist = false
		_ani.save()
		remove()
	}
	
	private function addMetadataPanel():void {
		addElement( new ComponentSpacer( width ) )
		addElement( new ComponentTextInput( "Name"
										  , function ($e:TextEvent):void { _ani.name = $e.target.text; setChanged(); }
										  , _ani.name ? _ani.name : "No Name"
										  , width ) )
		addElement( new ComponentTextArea( "Desc"
										 , function ($e:TextEvent):void { _ani.description = $e.target.text; setChanged(); }
										 , _ani.description ? _ani.description : "No Description"
										 , width ) )
		addElement( new ComponentLabel( "AnimationClass", _ani.animationClass, width ) )
		addElement( new ComponentLabel( "Type", _ani.type, width ) )
		
	}
	
	private function setChanged():void {
		_ani.changed = true
	}
	
	private function addAnimationsPanel():void {
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.title = " animated elements ";
		ebco.width = WIDTH;
		ebco.rootObject = _ani;
		ebco.items = _ani.transforms as Vector.<*>;
		ebco.itemDisplayObject = PanelAnimationTransform;
		ebco.itemBox.newItemText = "Add transforms";
		ebco.paddingTop = 7;
		addElement( new PanelVectorContainer( null, ebco ) )
	}
	
	private function addSoundPanel():void {
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.title = " animationSound "
		ebco.width = WIDTH
		ebco.rootObject = _ani
		ebco.item = _ani.animationSound
		ebco.itemBox.newItemText = "Add a Sound"
		ebco.paddingTop = 7
        ebco.itemBox.showNew = true;
        ebco.itemBox.title = "Add a Sound(1)";
		addElement( new PanelAnimationSound( null, ebco ) )
	}
/*	
	private function addAttachmentPanel():void {
		const showNewItem:Boolean = true
		addElement( new PanelVectorContainer( "Attachments to be used"
											, _ani
		                                    , _ani.attachments as Vector.<*>
											, PanelAnimationAttachment
											, "Add a new attachment"
											, WIDTH
											, showNewItem ) )
	}
	*/
}
}