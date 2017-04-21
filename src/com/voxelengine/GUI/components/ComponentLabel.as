/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.TextInput;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentLabel extends Box
{
	public function ComponentLabel( $label:String, $initialValue:String, $width:int, $height:int = 32, $padding:int = 8 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = $label;
		borderStyle = BorderStyle.GROOVE;
		
		addElement( new Label( $initialValue, $width - 20 ) );
	}
}
}