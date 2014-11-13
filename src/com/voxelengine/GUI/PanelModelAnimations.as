
package com.voxelengine.GUI
{
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.containers.UIContainer;	
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.VoxelModel;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelModelAnimations extends Box
	{
		private var _listModels:PanelModels;
		private var _listAnimations:PanelAnimations;
		private var _childPanel:PanelModelAnimations;
		private var _parent:*;
		
		private const width_default:int = 200;
		private const height_default:int = 150;
		private const pbPadding:int = 5;
		
		public function PanelModelAnimations( $parent:UIContainer )
		{
			super( width_default, height_default, BorderStyle.GROOVE );
			autoSize = true;
			backgroundColor = 0xCCCCCC;
			padding = pbPadding - 1;
			layout.orientation = LayoutOrientation.VERTICAL;
			_parent = $parent;
			
			modelPanelAdd();
        }
		
		public function updateChildren( $dictionarySource:Function ):void {
			if ( null != _listModels )
				_listModels.populateModels( $dictionarySource );
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
			_childPanel.updateChildren( $selectedModel.childrenGet );
			var topLevel:UIContainer = topLevelGet() as UIContainer;
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
		
		public function topLevelGet():* {
			if ( null == _parent )
				return this;
			if ( _parent )
				return _parent.topLevelGet();
			return null;	
		}
		
		public function recalc( width:Number, height:Number ):void {
			_parent.recalc( width, height );
		}
	}
}