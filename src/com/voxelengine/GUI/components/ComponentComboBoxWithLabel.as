/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.containers.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentComboBoxWithLabel extends Box
{
	private var _cbType:ComboBox  = new ComboBox();
	
	public function ComponentComboBoxWithLabel( $label:String, $changeHandler:Function, $initialValue:String, $types:Vector.<String>, data:*, $width:int, $height:int = 35, $padding:int = 2 )
	{
		super( $width, $height );
		addElement( new Label( $label, int($width * 0.35) ) );
		
		padding = $padding;
		paddingTop = $padding + 3;
		backgroundColor = VVUI.DEFAULT_COLOR;
		borderStyle = BorderStyle.NONE;
		
		_cbType.autoSize = false;
		_cbType.width = int($width * 0.60);
		for ( var i:int = 0; i < $types.length; i++ ) {
			_cbType.addItem( $types[i], data[i] );

		}
		setComboProp( $initialValue );

		addElement( _cbType );
		eventCollector.addEvent( _cbType, ListEvent.LIST_CHANGED, $changeHandler );
	}

	public function setComboProp(value:Object):void {
		var val:String = String(value).toLowerCase();
		var v:String = _cbType.value.toLowerCase();
		if (v == val) return;
		var l:int = _cbType.length - 1;
		for (; l >= 0; l--) {
			v = _cbType.getItemAt(l).value.toLowerCase();
			if (v == val) {
				_cbType.selectedIndex = l;
				return;
			}
		}
	}
	

	public function get selectedItemValue():String {
		if ( -1 == _cbType.selectedIndex )
			return "-1";
		return _cbType.getItemAt( _cbType.selectedIndex ).value;
	}
	public function get selectedItemData():* {
		if ( -1 == _cbType.selectedIndex )
			return -1;
		return _cbType.getItemAt( _cbType.selectedIndex ).data;
	}
}
}