/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {

public class PanelModelTransformContainer extends ExpandableBox {
	
	// Note: item in vector needs to have a "name" method
	public function PanelModelTransformContainer( $ebco:ExpandableBoxConfigObject ) {
		super( $ebco )
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
			ebco.itemBox.showDelete = true;
			var item:* = new _ebco.itemDisplayObject( ebco );
			_itemBox.addElement( item );
		}
	}
	override protected function collapasedInfo():String  {
		return "PMTC " + String( _ebco.items.length ) + " " + _ebco.itemBox.title;
	}
}
}