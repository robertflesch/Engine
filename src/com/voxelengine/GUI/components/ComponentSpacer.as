
package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentSpacer extends Box
{
	public function ComponentSpacer( $width:int, $height:int = 10, $padding:int = 0 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = SpasUI.DEFAULT_COLOR;

		borderStyle = BorderStyle.NONE;
	}
}
}