/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.worldmodel.weapons.Gun;

import org.flashapi.swing.*;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.event.*;

import com.voxelengine.Log;
import com.voxelengine.events.UIRegionModelEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import org.flashapi.swing.layout.AbsoluteLayout;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModelDetails extends PanelBase
{
	private var _parentModel:VoxelModel;
	private var _listModels:PanelModels;
	private var _listAnimations:PanelAnimations;
	private var _listScripts:PanelModelScripts;
	private var _listAmmo:PanelModelAmmo;
	private var _childPanel:PanelModelDetails;
	private var _aniButton:Button;
	private var _scriptsButton:Button;
	private var _level:int;
	private var _btnWidth:int;
	private var _selectedModel:VoxelModel;
	public function get selectedModel():VoxelModel { return _selectedModel; }
	public function set selectedModel( $vm:VoxelModel ):void { _selectedModel = $vm; }

	private const WIDTH_DEFAULT:int = 200;
	private const HEIGHT_DEFAULT:int = 300;
	private const HEIGHT_LIST_DEFAULT:int = 150;
	private var height_calculated:int;
	
	public function PanelModelDetails($parent:PanelBase, $level:int ) {
		super( $parent, WIDTH_DEFAULT, HEIGHT_DEFAULT );
		_level = $level;
		borderStyle = BorderStyle.GROOVE;
		layout = new AbsoluteLayout();
		modelPanelAdd();
		padding = 2;
		_btnWidth = width - 10;

		Log.out( "PanelModelDetails addListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged )", Log.WARN );
		UIRegionModelEvent.addListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
		UIRegionModelEvent.addListener( UIRegionModelEvent.SELECTED_MODEL_REMOVED, selectedModelRemoved );
	}
	
	override public function close():void {
		super.close();
		Log.out( "PanelModelDetails.CLOSE removeListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged )", Log.WARN );
		UIRegionModelEvent.removeListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
		UIRegionModelEvent.removeListener( UIRegionModelEvent.SELECTED_MODEL_REMOVED, selectedModelRemoved );

		modelPanelRemove();
		childPanelRemove();
		scriptPanelRemove();
		animationPanelRemove();
		removeButtons();
		_parentModel = null;
	}
	
	private function selectedModelChanged(e:UIRegionModelEvent):void {
		if ( e.level == _level ) {
			selectedModel = e.voxelModel;
			Log.out("PanelModelDetails.selectedModelChanged - level: " + _level + "  selectedModel: " + ( selectedModel ? selectedModel.metadata.name : "NONE") + "  parentModel: " + ( _parentModel ? _parentModel.metadata.name : "No parent" ), Log.WARN);
			if ( null == e.voxelModel )
				childPanelRemove();
			// true if our child changed the model
			else if (e.parentVM == _parentModel) {
				//Log.out( "PanelModelDetails.selectedModelChanged");
				childPanelAdd(e.voxelModel);
				removeListsAndButtons();
				addListsAndButtons(e.voxelModel);
			}
		} else if ( e.level < _level ) {
			childPanelRemove();
			removeListsAndButtons();
		}
		// ELSE do nothing, the parent will control it.
	}

	private function removeListsAndButtons():void {
		animationPanelRemove();
		animationButtonRemove();
		scriptPanelRemove();
		scriptButtonRemove();
		ammoPanelRemove();
		height_calculated = _listModels.height;
	}

	private function addListsAndButtons( $vm:VoxelModel ):void {
		if ( $vm.modelInfo.animations.length ) {
			animationPanelAdd($vm);
		} else {
			animationButtonAdd($vm);
		}

		if ( $vm.instanceInfo.scripts.length ) {
			scriptPanelAdd($vm);
		} else {
			scriptButtonAdd($vm);
		}

		if ( $vm is Gun )
			ammoPanelAdd( $vm as Gun );

		height = height_calculated;
	}
	
	private function selectedModelRemoved(e:UIRegionModelEvent):void {
		if ( _level >= e.level ) {
			removeListsAndButtons();
		}
	}

	public function updateChildren( $source:Function, $parentModel:VoxelModel, $removeAniAndScripts:Boolean = false ):void {
		_parentModel = $parentModel;
		var countAdded:int = _listModels.populateModels( $source, $parentModel );
//				if ( 0 == countAdded )
			childPanelRemove();

		if ( $removeAniAndScripts ) {
			removeListsAndButtons();
		}
	}

	private function removeButtons():void {
		scriptButtonRemove();
		animationButtonRemove();
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private function modelPanelAdd():void {
		if ( null == _listModels ) {
			_listModels = new PanelModels( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT, _level );
			addElement( _listModels );
		}
	}
	
	private function modelPanelRemove():void {
		if (_listModels)
			_listModels.close();
		_listModels = null;
	}

	public function childPanelAdd( $selectedModel:VoxelModel ):void {
		if ( null == _childPanel ) 
			_childPanel = new PanelModelDetails( _parent, (_level + 1) );
		_childPanel.updateChildren( $selectedModel.modelInfo.childVoxelModelsGet, $selectedModel );
		var topLevel:PanelBase = topLevelGet();
		topLevel.addElement( _childPanel );
		
	}

	public function childPanelRemove():void {
		if ( null != _childPanel ) {
			_childPanel.remove();
			_childPanel = null;
		}
	}

	//////////////////////////////////////////////////////////////////////////
	public function animationPanelAdd( $vm:VoxelModel ):void {
		if ( null == _listAnimations ) {
			_listAnimations = new PanelAnimations( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT, _level );
			_listAnimations.y = height_calculated;
			addElement( _listAnimations );
			height_calculated += _listAnimations.height;
		}

		_listAnimations.populateAnimations( $vm );
	}

	public function animationPanelRemove():void {
		if ( null != _listAnimations ) {
			removeElement(_listAnimations);
			_listAnimations = null;
		}
	}

	private function animationButtonAdd($vm:VoxelModel):void {
		_aniButton = new Button( LanguageManager.localizedStringGet( "Add_an animation" ) );
		_aniButton.x = 5;
		_aniButton.y = height_calculated;
		_aniButton.width = _btnWidth;
		_aniButton.enabled = true;
		_aniButton.eventCollector.addEvent( _aniButton, UIMouseEvent.CLICK, function (e:UIMouseEvent):void { removeElement( e.target ); animationPanelAdd( $vm ) } );
		addElement( _aniButton );
		height_calculated += HEIGHT_BUTTON_DEFAULT;
	}
	
	public function animationButtonRemove():void {
		if ( _aniButton ) { 
			removeElement(_aniButton);
			_aniButton = null 
		} 
	}
	//////////////////////////////////////////////////////////////////////////
	
	public function scriptPanelAdd( $vm:VoxelModel ):void {
		if ( null == _listScripts ) {
			_listScripts = new PanelModelScripts( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT - 100 );
			_listScripts.y = height_calculated;
			addElement( _listScripts );
			height_calculated += _listScripts.height;
		}

		_listScripts.populateScripts( $vm );
		//recalc( width, height );
	}

	public function scriptPanelRemove():void {
		if (null != _listScripts) {
			removeElement(_listScripts);
			_listScripts = null;
		}
	}

	public function scriptButtonRemove():void {
		if ( _scriptsButton ) {
			removeElement(_scriptsButton);
			_scriptsButton = null
		}
	}

	private function scriptButtonAdd($vm:VoxelModel):void {
		_scriptsButton = new Button( LanguageManager.localizedStringGet( "Add a script" ) );
		_scriptsButton.x = 5;
		_scriptsButton.y = height_calculated;
		_scriptsButton.width = _btnWidth;
		_scriptsButton.enabled = true;
		_scriptsButton.eventCollector.addEvent( _scriptsButton, UIMouseEvent.CLICK, function (e:UIMouseEvent):void { removeElement( e.target ); scriptPanelAdd( $vm ) } );
		addElement( _scriptsButton );
		height_calculated += HEIGHT_BUTTON_DEFAULT;
	}

	//////////////////////////////////////////////////////////////////////////
	
	public function ammoPanelAdd( $vm:Gun ):void {
		if ( null == _listAmmo ) {
			_listAmmo = new PanelModelAmmo( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT );
			_listAmmo.y = height_calculated;
			addElement( _listAmmo );
			height_calculated += _listAmmo.height;
		}

		_listAmmo.populateAmmos( $vm );
		//recalc( width, height );
	}

	public function ammoPanelRemove():void {
		if (null != _listAmmo) {
			removeElement(_listAmmo);
			_listAmmo = null;
		}
	}

//	private function addButtonAmmo($vm:Gun):void {
//		_ammoButton = new Button( LanguageManager.localizedStringGet( "Add Ammo" ) );
//		_ammoButton.width = width - 10;
//		_ammoButton.enabled = true;
//		//_ammoButton.active = false;
//		_ammoButton.eventCollector.addEvent( _ammoButton, UIMouseEvent.CLICK, function (e:UIMouseEvent):void { removeElement( e.target ); ammoPanelAdd( $vm ) } );
//		_ammoButton.width = _listModels.width - 10;
//		addElement( _ammoButton );
//	}


}
}