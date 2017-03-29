/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.panels
{
	import com.voxelengine.GUI.panels.PanelAnimations;
	import com.voxelengine.GUI.panels.PanelBase;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.UIRegionModelEvent;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelModelDetails extends PanelBase
	{
		private var _parentModel:VoxelModel;
		private var _listModels:PanelModels;
		private var _listAnimations:PanelAnimations;
		private var _listScripts:PanelModelScripts;
		private var _childPanel:PanelModelDetails;
		private var _level:int;
		
		private const width_default:int = 200;
		private const height_default:int = 150;
		
		public function PanelModelDetails($parent:PanelBase, $level:int ) {
			super( $parent, width_default, height_default );
			_level = $level;
			modelPanelAdd();
			
			UIRegionModelEvent.addListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
        }
		
		override public function close():void {
			super.close();
			UIRegionModelEvent.removeListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
			
			_listModels.close();
			_listModels = null;
			
			if ( _childPanel ) {
				_childPanel.close();
				_childPanel = null;
			}
			
			if ( _listScripts ) {
				_listScripts.close();
				_listScripts = null;
			}

			if ( _listAnimations ) {
				_listAnimations.close();
				_listAnimations = null;
			}

			_parentModel = null;
		}
		
		private function selectedModelChanged(e:UIRegionModelEvent):void 
		{
			//Log.out( "PanelModelDetails.selectedModelChanged - parentModel: " + ( _parentModel ? _parentModel.metadata.name : "No parent" ), Log.WARN );
			if ( null == e.voxelModel && _parentModel == e.parentVM )
				childPanelRemove();
			// true if our child changed the model
			else if ( e.parentVM == _parentModel ) {
				//Log.out( "PanelModelDetails.selectedModelChanged");
				childPanelAdd( e.voxelModel );
				animationPanelAdd( e.voxelModel );
				scriptPanelAdd( e.voxelModel );
			}
		}
		
		public function updateChildren( $source:Function, $parentModel:VoxelModel, $removeAniAndScripts:Boolean = false ):void {
			_parentModel = $parentModel;
			if ( null != _listModels ) {
				var countAdded:int = _listModels.populateModels( $source, $parentModel );
//				if ( 0 == countAdded )
					childPanelRemove();

				if ( $removeAniAndScripts ) {
					animationPanelRemove();
					scriptPanelRemove();
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function modelPanelAdd():void {

			if ( null == _listModels ) {
				_listModels = new PanelModels( this, width_default, 15, height_default, _level );
				addElement( _listModels );
			}
			//recalc( width, height );
		}
		
		public function childPanelAdd( $selectedModel:VoxelModel ):void {
			if ( null == _childPanel ) 
				_childPanel = new PanelModelDetails( _parent, (_level + 1) );
			_childPanel.updateChildren( $selectedModel.modelInfo.childVoxelModelsGet, $selectedModel );
			var topLevel:PanelBase = topLevelGet();
			topLevel.addElement( _childPanel );
			
		}
		
		public function animationPanelAdd( $vm:VoxelModel ):void {
			if ( null == _listAnimations ) {
				_listAnimations = new PanelAnimations( this, width_default, 15, height_default, _level );
				addElement( _listAnimations );
			}

			_listAnimations.populateAnimations( $vm );
			//recalc( width, height );
		}

		public function animationPanelRemove():void {
			if ( null != _listAnimations ) {
				removeElement(_listAnimations);
				_listAnimations = null;
			}
		}

		public function scriptPanelAdd( $vm:VoxelModel ):void {
			if ( null == _listScripts ) {
				_listScripts = new PanelModelScripts( this, width_default, 15, height_default );
				addElement( _listScripts );
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

		public function childPanelRemove():void {
			if ( null != _childPanel ) {
				_childPanel.remove();
				_childPanel = null;
			}
		}
	}
}