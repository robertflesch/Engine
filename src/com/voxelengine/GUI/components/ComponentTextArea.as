/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.TextArea;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentTextArea extends Box
{
	public function ComponentTextArea( $label:String, $changeHandler:Function, $initialValue:String, $width:int, $height:int = 90, $padding:int = 5 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = $label;
		borderStyle = BorderStyle.GROOVE;
		
		var li:TextArea = new TextArea();
		li.appendText( $initialValue );
		li.width = $width - 20;
		li.addEventListener( TextEvent.EDITED, $changeHandler );
			
		addElement( li );
	}
}
}