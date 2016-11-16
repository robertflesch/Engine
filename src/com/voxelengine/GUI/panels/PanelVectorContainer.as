/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
	
import org.flashapi.swing.event.UIMouseEvent;

public class PanelVectorContainer extends ExpandableBox {
	
	// Note: item in vector needs to have a "name" method
	public function PanelVectorContainer( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {
		super( $parent, $ebco )
	}
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.height = 0;
		for ( var i:int; i < _ebco.items.length; i++ ) {
			var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
			ebco.rootObject = _ebco.rootObject
			ebco.item = _ebco.items[i]
			ebco.items = _ebco.items
			ebco.width = _itemBox.width
			ebco.title = ""
			var item:* = new _ebco.itemDisplayObject( this, ebco );
			_itemBox.addElement( item );
		}
	}
	
	override protected function collapasedInfo():String  {
		return String( _ebco.items.length ) + " " + _ebco.itemBox.title;
	}

	// This handles the new model transform
	override protected function newItemHandler( $me:UIMouseEvent ):void 		{

		_itemBox.addElement( new _ebco.itemDisplayObject( this, _ebco ) );
		changeMode() // collapse container
		changeMode() // reexpand so that new item is at the bottom
	}


}
}