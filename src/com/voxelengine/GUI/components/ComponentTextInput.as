
package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.TextInput;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.SpasUI;

//import com.voxelengine.Log;

public class ComponentTextInput extends Box
{
	private var _li:TextInput
	public function ComponentTextInput( label:String, changeHandler:Function, initialValue:String, $width:int, $height:int = 30, $padding:int = 5 )
	{
		super( $width, $height );
		
		padding = $padding;
		paddingTop = $padding + 3;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = label;
		borderStyle = BorderStyle.GROOVE;
		
		_li = new VVTextInput(initialValue,$width - 20);
		_li.addEventListener( TextEvent.EDITED, changeHandler );
			
		addElement( _li );
	}
}
}