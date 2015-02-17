/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.worldmodel.animation.AnimationAttachment;
import com.voxelengine.worldmodel.MemoryManager;
import flash.display.Bitmap;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.UIContainer;	

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.models.VoxelModel;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelAnimations extends PanelBase
{
	private var _listAnimations:			ListBox;
	private var _selectedAnimation:			Animation;
	private var _buttonContainer:			Container;
	private var _addButton:					Button;
	private var _deleteButton:				Button;
	private var _detailButton:				Button;
	
	public function PanelAnimations( $parent:PanelModelAnimations, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
	{
		super( $parent, $widthParam, $heightParam );
		
		var ha:Label = new Label( "Has Animations", width );
		ha.textAlign = TextAlign.CENTER;
		addElement( ha );
		
		_listAnimations = new ListBox(  width - pbPadding, $elementHeight, $heightParam );
		_listAnimations.eventCollector.addEvent( _listAnimations, ListEvent.LIST_CHANGED, select );			
		addElement( _listAnimations );
		
		animationButtonsCreate();
		//addEventListener( UIMouseEvent.ROLL_OVER, rollOverHandler );
		//addEventListener( UIMouseEvent.ROLL_OUT, rollOutHandler );
		
		recalc( width, height );
	}
	
	override public function close():void {
		super.close();
		_listAnimations = null;
		_selectedAnimation = null;
		_buttonContainer = null;
	}
	
	private function rollOverHandler(e:UIMouseEvent):void 
	{
		if ( null == _buttonContainer )
			animationButtonsCreate();
	}
	
	private function rollOutHandler(e:UIMouseEvent):void 
	{
		if ( null != _buttonContainer ) {
			_buttonContainer.remove();
			_buttonContainer = null;
		}
	}
	
	public function populateAnimations( $vm:VoxelModel ):void
	{
		_listAnimations.removeAll();
		var anims:Vector.<Animation> = $vm.modelInfo.animations;
		for each ( var anim:Animation in anims )
		{
			_listAnimations.addItem( anim.name + " - " + anim.guid, anim );
		}
	}
	
	// FIXME This would be much better with drag and drop
	private function animationButtonsCreate():void {
		Log.out( "PanelAnimations.animationButtonsCreate - width: " + width + "  height: " + height );
		_buttonContainer = new Container( width, 100 );
		_buttonContainer.layout.orientation = LayoutOrientation.VERTICAL;
		_buttonContainer.padding = 2;
		_buttonContainer.height = 0;
		
		addElement( _buttonContainer );

		_addButton = new Button( LanguageManager.localizedStringGet( "Animation_Add" )  );
		_addButton.eventCollector.addEvent( _addButton, UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowAnimationDetail( null ); } );
		_addButton.width = width - 2 * pbPadding;
		_buttonContainer.addElement( _addButton );
		_buttonContainer.height += _addButton.height + pbPadding;
		
		_deleteButton = new Button( LanguageManager.localizedStringGet( "Animation_Delete" ) );
		_deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteAnimationHandler );
		_deleteButton.enabled = false;
		_deleteButton.active = false;
		_deleteButton.width = width - 2 * pbPadding;
		_buttonContainer.addElement( _deleteButton );
		_buttonContainer.height += _deleteButton.height + pbPadding;
		
		_detailButton = new Button( LanguageManager.localizedStringGet( "Animation_Detail" ) );
		_detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, animationDetailHandler );
		_detailButton.enabled = false;
		_detailButton.active = false;
		_detailButton.width = width - 2 * pbPadding;
		_buttonContainer.addElement( _detailButton );
		
		function deleteAnimationHandler(event:UIMouseEvent):void  {
			if ( _selectedAnimation )
			{
				(new Alert( LanguageManager.localizedStringGet( "NOT IMPLEMENTED" ) )).display();
			}
			else
				noAnimationSelected();
		}
		Log.out( "PanelAnimations.animationButtonsCreate AFTER - width: " + width + "  height: " + height + " buttoncontainer - AFTER - width: " + _buttonContainer.width + "  height: " + _buttonContainer.height );
	}
	
	private function select(event:ListEvent):void 
	{
		_selectedAnimation = event.target.data;
		if ( _selectedAnimation )
		{
			_detailButton.enabled = true;
			_detailButton.active = true;
			_deleteButton.enabled = true;
			_deleteButton.active = true;
		}
		else {
			_detailButton.enabled = false;
			_detailButton.active = false;
			_deleteButton.enabled = false;
			_deleteButton.active = false;
		}
	}
	
	
	private function animationDetailHandler(event:UIMouseEvent):void 
	{ 
		//new WindowModelList();
		new WindowAnimationDetail( _selectedAnimation );	
	}
		
	///////////////////////////////////////////////////////////////////////
	
	private function noAnimationSelected():void
	{
		(new Alert( LanguageManager.localizedStringGet( "No_Animation_Selected" ) )).display();
	}
}
}