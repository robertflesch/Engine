/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.CheckBox
import org.flashapi.swing.Container;
import org.flashapi.swing.Label;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.plaf.spas.VVUI;
import org.flashapi.swing.constants.*;

public class ComponentCheckBox extends Container
{
	private var _cb:CheckBox;
	public function ComponentCheckBox( $label:String, $initialValue:Boolean, $width:int, $clickHandler:Function )
	{
		super( $width, 25 );
	
		layout.orientation = LayoutOrientation.HORIZONTAL;
		padding = 3;
		backgroundColor = VVUI.DEFAULT_COLOR;
		
		addElement( new Label( $label, ($width - 20) * 0.40 ) );
		//addElement( new Label( $initialValue, ($width - 20) * 0.60 ) )
		
		_cb = new CheckBox( "", ($width - 20) * 0.60 );
		_cb.selected = $initialValue;
		eventCollector.addEvent( _cb, UIMouseEvent.CLICK, $clickHandler );
		addElement( _cb );
	}

	public function set selected( $val:Boolean ):void {
		_cb.selected = $val;
	}
}
}