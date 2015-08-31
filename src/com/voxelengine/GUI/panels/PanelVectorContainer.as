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
	private var _vector:Vector.<*>;
	private var _itemDisplayObject:Class;
	private var _rootObject:*;
	
	// Note: item in vector needs to have a "name" method
	public function PanelVectorContainer( $title:String, $rootObject:*, $vector:Vector.<*> , $itemDisplayObject:Class, $newItemName:String, $widthParam:int ) {
		_vector = $vector;
		_itemDisplayObject = $itemDisplayObject;
		_rootObject = $rootObject;
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
		ebco.title = $title;
		ebco.newItemText = $newItemName;
		ebco.width = $widthParam;
		ebco.showDelete = false;
		ebco.paddingTop = 10;
		ebco.paddingLeft = 6;
		super( ebco );
	}
	
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.height = 0;
		for ( var i:int; i < _vector.length; i++ ) {
			var item:* = new _itemDisplayObject( _rootObject, _vector[i], _itemBox.width );
			_itemBox.addElement( item );
		}
	}
	override public function collapasedInfo():String  {
		return String( _vector.length );
	}
	

	//override public function deleteElementCheck( $me:UIMouseEvent ):void {
		//(new Alert( "PanelVectorContainer.deleteElementCheck", 350 )).display();
	//}
	
	override public function newItemHandler( $me:UIMouseEvent ):void  {
		var item:* = new _itemDisplayObject( _rootObject, null, _itemBox.width );
		_itemBox.addElement( item );
		resizePane( null );
	}
	
}
}