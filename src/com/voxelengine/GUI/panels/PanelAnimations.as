/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.GUI.animation.WindowAnimationDetail;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.GUI.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.models.types.VoxelModel;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelAnimations extends PanelBase
{
	private var _listAnimations:			ListBox;
	private var _level:						int;
	private var _selectedAnimation:			Animation;
	private var _buttonContainer:			Container;
	private var _addButton:					Button;
	private var _deleteButton:				Button;
	private var _detailButton:				Button;
	private var _selectedModel:				VoxelModel;
	private var _currentY:                  int;

	public function PanelAnimations($parent:ContainerModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number, $level:int )
	{
		super( $parent, $widthParam, $heightParam );
		_level = $level;
		autoHeight = false;
		layout = new AbsoluteLayout();

		var ha:Label = new Label( "Has Animations", width );
		ha.textAlign = TextAlign.CENTER;
		ha.y = _currentY;
		addElement( ha );

		_listAnimations = new ListBox(  $widthParam - 10, $elementHeight, $heightParam );
		_listAnimations.x = 5;
		_listAnimations.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT - 5;
		_listAnimations.eventCollector.addEvent( _listAnimations, ListEvent.LIST_CHANGED, select );
		addElement( _listAnimations );

		const btnWidth:int = $widthParam - 10;
		_addButton = new Button( LanguageManager.localizedStringGet( "Animation_Add" )  );
		_addButton.y = _currentY = _currentY + _listAnimations.height + 10;
		_addButton.x = 5;
		_addButton.eventCollector.addEvent( _addButton, UIMouseEvent.CLICK, function (event:UIMouseEvent):void { new WindowAnimationDetail( _selectedModel.modelInfo.guid, null ); } );
		_addButton.width = btnWidth;
		addElement( _addButton );

		_deleteButton = new Button( LanguageManager.localizedStringGet( "Animation_Delete" ) );
		_deleteButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
		_deleteButton.x = 5;
		_deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteAnimationHandler );
		_deleteButton.enabled = false;
		_deleteButton.width = btnWidth;
		addElement( _deleteButton );

		_detailButton = new Button( LanguageManager.localizedStringGet( "Animation_Detail" ) );
		_detailButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
		_detailButton.x = 5;
		_detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, animationDetailHandler );
		_detailButton.enabled = false;
		_detailButton.width = btnWidth;
		addElement( _detailButton );

		function deleteAnimationHandler(event:UIMouseEvent):void  {
			if ( _selectedAnimation )
			{
				var anim:Animation = _selectedAnimation;
				//(new Alert( LanguageManager.localizedStringGet( "NOT IMPLEMENTED" ) )).display();
				AnimationEvent.create( ModelBaseEvent.DELETE, 0, _selectedModel.modelInfo.guid, anim.guid, null );
				populateAnimations( _selectedModel );
				_selectedModel.modelInfo.changed = true;
				_selectedModel.save();
			}
			else
				noAnimationSelected();
		}

//		UIRegionModelEvent.addListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );

		_currentY = _currentY + HEIGHT_BUTTON_DEFAULT + 5;
		height =  _currentY;
		recalc( width, height );
	}

//	private function selectedModelChanged(e:UIRegionModelEvent):void {
//		// if the parent of the selected model has changed
//		// then we should clear the list, and wait for the next call to populate animation
//		if ( e.level <= _level )
//			_listAnimations.removeAll();
//		if ( e.level == _level )
//			populateAnimations( e.voxelModel);
//	}

	override public function remove():void {
		super.remove();
//		UIRegionModelEvent.removeListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
		_listAnimations = null;
		_selectedAnimation = null;
		_buttonContainer = null;
		_selectedModel = null;
	}
	
	public function populateAnimations( $vm:VoxelModel ):void
	{
		_listAnimations.removeAll();
		if ( !$vm ) {
			Log.out( "PanelAnimations.populateAnimations - $VM is NULL", Log.WARN );
			return;
		}
		_selectedModel = $vm;
		var anims:Vector.<Animation> = $vm.modelInfo.animations;
		for each ( var anim:Animation in anims )
		{
			_listAnimations.addItem( anim.name + " - " + anim.guid, anim );
		}
	}
	

	private function select(event:ListEvent):void 
	{
		_selectedAnimation = event.target.data;
		if ( _selectedAnimation )
		{
			_selectedModel.stateLock( false );
			_selectedModel.stateSet( _selectedAnimation.name ); 
			_selectedModel.stateLock( true );
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
		new WindowAnimationDetail( _selectedModel.modelInfo.guid, _selectedAnimation );	
	}
		
	///////////////////////////////////////////////////////////////////////
	
	private function noAnimationSelected():void
	{
		(new Alert( LanguageManager.localizedStringGet( "No_Animation_Selected" ) )).display();
	}
}
}