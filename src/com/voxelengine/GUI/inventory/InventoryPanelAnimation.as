/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.inventory {

	import org.flashapi.swing.*
	import org.flashapi.swing.core.UIObject;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelAnimation extends VVContainer
	{
		// This hold the items to be displayed
		private var _itemContainer:Container;
		
		public function InventoryPanelAnimation() {
			super( this );
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			addItemContainer();
		}
		
		private function addItemContainer():void {
			_itemContainer = new Container();
			_itemContainer.autoSize = true;
			_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
			addElement( _itemContainer );
		}
	}
}