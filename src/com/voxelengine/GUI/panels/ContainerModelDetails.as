/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{

import org.flashapi.swing.*;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.events.UIRegionModelEvent;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.worldmodel.weapons.Gun;
import com.voxelengine.worldmodel.models.types.VoxelModel;


// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class ContainerModelDetails extends PanelBase
{
	static private const BTN_WIDTH:int = 190;
	static private const WIDTH_DEFAULT:int = 200;
	static private const HEIGHT_DEFAULT:int = 390;
	static private const HEIGHT_LIST_DEFAULT:int = 250;

	private var _parentModel:VoxelModel;
	private var _listModels:PanelModelsListFromRegion;
	private var _listAnimations:PanelAnimations;
	private var _listScripts:PanelModelScripts;
	private var _listAmmo:PanelModelAmmo;
	private var _childPanel:ContainerModelDetails;
	private var _aniButton:Button;
	private var _scriptsButton:Button;
	private var _level:int;
	private var height_calculated:int;

	private var _selectedModel:VoxelModel;
	public function get selectedModel():VoxelModel { return _selectedModel; }
	public function set selectedModel( $vm:VoxelModel ):void {
		if ( 0 == _level ) {
            VoxelModel.selectedModel = $vm;
			if ( $vm )
            	VoxelModel.selectedModel.selected = true;
			else {
                if ( VoxelModel.selectedModel )
					VoxelModel.selectedModel.selected = false;
            }
        }
		_selectedModel = $vm;
	}

	public function ContainerModelDetails($parent:PanelBase, $level:int ) {
		super( $parent, WIDTH_DEFAULT, HEIGHT_DEFAULT );
		_level = $level;
		borderStyle = BorderStyle.GROOVE;
		layout = new AbsoluteLayout();
		modelPanelAdd();

		UIRegionModelEvent.addListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
	}
	
	override public function remove():void {
		UIRegionModelEvent.removeListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );

		childPanelRemove();
		removeListsAndButtons();
		modelPanelRemove();
		_parentModel = null;
		_selectedModel = null;

		super.remove();
	}
	
	private function selectedModelChanged(e:UIRegionModelEvent):void {
		//Log.out("PanelModelDetails.selectedModelChanged - level: " + _level + "  e.level: " + e.level );
		if ( e.level == _level ) {
			selectedModel = e.voxelModel;
			//Log.out("PanelModelDetails.selectedModelChanged - selectedModel: " + selectedModel + " e.parentVM: " + e.voxelModel + "  _parentModel: " + _parentModel, Log.WARN);
			childPanelRemove();
			removeListsAndButtons();
			if ( selectedModel && 0 < selectedModel.modelInfo.childCount ) {
				//Log.out("PanelModelDetails.selectedModelChanged - selectedModel.metadata.name: " + selectedModel.metadata.name, Log.WARN );
				childPanelAdd( selectedModel );
				addListsAndButtons( selectedModel );
			}
		}
		height = height_calculated;
		//Log.out("==============================================================" );
	}

	public function updateChildren( $source:Function, $parentModel:VoxelModel, $removeAniAndScripts:Boolean = false ):void {
		_parentModel = $parentModel;
		var countAdded:int = _listModels.populateModels( $source, $parentModel );
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
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private function modelPanelAdd():void {
		if ( null == _listModels ) {
			_listModels = new PanelModelsListFromRegion( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT, _level );
			addElement( _listModels );
		}
	}
	
	private function modelPanelRemove():void {
		if (_listModels)
			_listModels.remove();
		_listModels = null;
	}

	public function childPanelAdd( $selectedModel:VoxelModel ):void {
		if ( null == _childPanel ) 
			_childPanel = new ContainerModelDetails( _parent, (_level + 1) );
		_childPanel.updateChildren( $selectedModel.modelInfo.childVoxelModelsGet, $selectedModel );
		var topLevel:PanelBase = topLevelGet();
		topLevel.addElement( _childPanel );
		
	}

	public function childPanelRemove():void {
		if ( null != _childPanel ) {
			_childPanel.remove(); // removes from display list
			_childPanel = null;
		}
	}

	//////////////////////////////////////////////////////////////////////////
	public function animationPanelAdd( $vm:VoxelModel ):void {
		if ( null == _listAnimations ) {
			_listAnimations = new PanelAnimations( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT/2, _level );
			_listAnimations.y = height_calculated;
			addElement( _listAnimations );
			height_calculated += _listAnimations.height;
		}

		_listAnimations.populateAnimations( $vm );
	}

	public function animationPanelRemove():void {
		if ( null != _listAnimations ) {
			_listAnimations.remove();
			removeElement(_listAnimations);
			_listAnimations = null;
		}
	}

	private function animationButtonAdd($vm:VoxelModel):void {
		_aniButton = new Button( LanguageManager.localizedStringGet( "add_an_animation" ) );
		_aniButton.x = 5;
		_aniButton.y = height_calculated + 5;
		_aniButton.width = BTN_WIDTH;
		_aniButton.enabled = true;
		_aniButton.eventCollector.addEvent( _aniButton, UIMouseEvent.CLICK, function (e:UIMouseEvent):void { removeElement( e.target ); animationPanelAdd( $vm ) } );
		addElement( _aniButton );
		height_calculated += HEIGHT_BUTTON_DEFAULT + 10;
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
			_listScripts = new PanelModelScripts( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT/3 );
			_listScripts.y = height_calculated;
			addElement( _listScripts );
			height_calculated += _listScripts.height;
		}

		_listScripts.populateScripts( $vm );
		height = height_calculated;
	}

	public function scriptPanelRemove():void {
		if (null != _listScripts) {
			_listScripts.remove();
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
		_scriptsButton = new Button( LanguageManager.localizedStringGet( "add_a_script" ) );
		_scriptsButton.x = 5;
		_scriptsButton.y = height_calculated + 5;
		_scriptsButton.width = BTN_WIDTH;
		_scriptsButton.enabled = true;
		_scriptsButton.eventCollector.addEvent( _scriptsButton, UIMouseEvent.CLICK, function (e:UIMouseEvent):void { removeElement( e.target ); scriptPanelAdd( $vm ) } );
		addElement( _scriptsButton );
		height_calculated += HEIGHT_BUTTON_DEFAULT + 10;
	}

	//////////////////////////////////////////////////////////////////////////
	
	public function ammoPanelAdd( $vm:Gun ):void {
		if ( null == _listAmmo ) {
			_listAmmo = new PanelModelAmmo( this, WIDTH_DEFAULT, 15, HEIGHT_LIST_DEFAULT/3 );
			_listAmmo.y = height_calculated;
			addElement( _listAmmo );
			height_calculated += _listAmmo.height;
		}

		_listAmmo.populateAmmos( $vm );
	}

	public function ammoPanelRemove():void {
		if (null != _listAmmo) {
			removeElement(_listAmmo);
			_listAmmo = null;
		}
	}
}
}