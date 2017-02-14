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
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentComboBoxWithLabel extends Box
{
	private var _cbType:ComboBox  = new ComboBox()
	
	public function ComponentComboBoxWithLabel( $label:String, $changeHandler:Function, $initialValue:String, $types:Vector.<String>, $width:int, $height:int = 35, $padding:int = 2 )
	{
		super( $width, $height );
		addElement( new Label( $label, int($width * 0.35) ) );
		
		padding = $padding;
		paddingTop = $padding + 3;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		borderStyle = BorderStyle.NONE;
		
		_cbType.autoSize = false;
		_cbType.width = int($width * 0.60)
		for each ( var item:String in $types ) {
			_cbType.addItem( item );
		}
		for ( var j:int; j < $types.length; j++ ) {
			if ( $types[j] == $initialValue )
				_cbType.selectedIndex = j;		
		}
		addElement( _cbType );
		eventCollector.addEvent( _cbType, ListEvent.LIST_CHANGED, $changeHandler );
	}
}
}