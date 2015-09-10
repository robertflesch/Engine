/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.GUI.*;

public class PanelVectorContainer extends ExpandableBox {
	
	// Note: item in vector needs to have a "name" method
	public function PanelVectorContainer( $ebco:ExpandableBoxConfigObject ) {
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
			var item:* = new _ebco.itemDisplayObject( ebco );
			//var item:* = new _ebco.itemDisplayObject( _ebco.rootObject, _ebco.items[i], _itemBox.width );
			_itemBox.addElement( item );
		}
	}
	override public function collapasedInfo():String  {
		return String( _ebco.items.length ) + " " + _ebco.itemBox.title;
	}
	

	//override public function deleteElementCheck( $me:UIMouseEvent ):void {
		//(new Alert( "PanelVectorContainer.deleteElementCheck", 350 )).display();
	//}
	
	override public function newItemHandler( $me:UIMouseEvent ):void  {
		var item:* = new _ebco.itemDisplayObject( _ebco.rootObject, null, _itemBox.width );
		_itemBox.addElement( item );
		resizePane( null );
	}
	
}
}