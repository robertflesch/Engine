/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {

import org.flashapi.swing.TextInput;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.VVUI;;

public class ComponentCompactTextInput extends Panel
{
	public function ComponentCompactTextInput( label:String, changeHandler:Function, initialValue:String, $width:int, $height:int = 50, $padding:int = 15 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = VVUI.DEFAULT_COLOR;
		//title = label;
		//borderStyle = BorderStyle.GROOVE;
		
		var li:TextInput = new VVTextInput( "", 50 );
		li.text = initialValue;
		li.width = $width - 20;
		li.addEventListener( TextEvent.EDITED, changeHandler );
			
		addElement( li );
	}
}
}