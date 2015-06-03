
package com.voxelengine.GUI.voxelModels
{
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.UIRegionModelEvent;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelModelAnimations extends PanelBase
	{
		private var _parentModel:VoxelModel;
		private var _listModels:PanelModels;
		private var _listAnimations:PanelAnimations;
		private var _childPanel:PanelModelAnimations;
		
		private const width_default:int = 200;
		private const height_default:int = 150;
		
		public function PanelModelAnimations( $parent:PanelBase )
		{
			super( $parent, width_default, height_default );
			
			modelPanelAdd();
			
			Globals.g_app.addEventListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
        }
		
		override public function close():void {
			super.close();
			Globals.g_app.removeEventListener( UIRegionModelEvent.SELECTED_MODEL_CHANGED, selectedModelChanged );
			
			_listModels.close();
			_listModels = null;
			
			if ( _childPanel ) {
				_childPanel.close();
				_childPanel = null;
			}
			
			if ( _listAnimations ) {
				_listAnimations.close();
				_listAnimations = null;
			}
			_parentModel = null;
		}
		
		private function selectedModelChanged(e:UIRegionModelEvent):void 
		{
			if ( null == e.voxelModel && _parentModel == e.parentVM )
				childPanelRemove();
			// true if our child changed the model
			else if ( e.parentVM == _parentModel ) {
				childPanelAdd( e.voxelModel );
				animationPanelAdd( e.voxelModel );
			}
		}
		
		public function updateChildren( $source:Function, $parentModel:VoxelModel ):void {
			_parentModel = $parentModel;
			if ( null != _listModels ) {
				var countAdded:int = _listModels.populateModels( $source, $parentModel );
				if ( 0 == countAdded )
					childPanelRemove();
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function modelPanelAdd():void {

			if ( null == _listModels ) {
				_listModels = new PanelModels( this, width_default, 15, height_default );
				addElement( _listModels );
			}
			//recalc( width, height );
		}
		
		public function childPanelAdd( $selectedModel:VoxelModel ):void {
			if ( null == _childPanel ) 
				_childPanel = new PanelModelAnimations( _parent );
			_childPanel.updateChildren( $selectedModel.modelInfo.childrenGet, $selectedModel );
			var topLevel:PanelBase = topLevelGet();
			topLevel.addElement( _childPanel );
			
		}
		
		public function animationPanelAdd( $vm:VoxelModel ):void {
			if ( null == _listAnimations ) {
				_listAnimations = new PanelAnimations( this, width_default, 15, height_default );
				addElement( _listAnimations );
			}

			_listAnimations.populateAnimations( $vm );
			//recalc( width, height );
		}
		
		public function childPanelRemove():void {
			if ( null != _childPanel ) {
				_childPanel.remove();
				_childPanel = null;
			}
		}
	}
}