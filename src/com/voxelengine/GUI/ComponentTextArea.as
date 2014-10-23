
package com.voxelengine.GUI 
{
import org.flashapi.swing.Box;
import org.flashapi.swing.TextArea;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;

public class ComponentTextArea extends Box
{
	public function ComponentTextArea( label:String, changeHandler:Function, initialValue:String, $width:int, $height:int = 150, $padding:int = 15 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = 0xCCCCCC;
		title = label;
		borderStyle = BorderStyle.GROOVE;
		
		var li:TextArea = new TextArea();
		li.appendText( initialValue );
		li.width = $width - 20;
		li.addEventListener( TextEvent.EDITED, changeHandler );
			
		addElement( li );
	}
}
}