
package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.TextInput;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentTextInput extends Box
{
	public function ComponentTextInput( label:String, changeHandler:Function, initialValue:String, $width:int, $height:int = 50, $padding:int = 15 )
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