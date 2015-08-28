
package com.voxelengine.GUI.components {

import org.flashapi.swing.TextInput;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentCompactTextInput extends Panel
{
	public function ComponentCompactTextInput( label:String, changeHandler:Function, initialValue:String, $width:int, $height:int = 50, $padding:int = 15 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = label;
		borderStyle = BorderStyle.GROOVE;
		
		var li:TextInput = new TextInput();
		li.text = initialValue;
		li.width = $width - 20;
		li.addEventListener( TextEvent.EDITED, changeHandler );
			
		addElement( li );
	}
}
}