
package com.voxelengine.GUI.components {

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.SpasUI;

public class ComponentLabelInput extends LabelInput
{
	public function ComponentLabelInput( $label:String, $changeHandler:Function, $initialValue:String, $width:int, $height:int = 20, $padding:int = 15 )
	{
		super( $label, $initialValue, $width )
		backgroundColor = SpasUI.DEFAULT_COLOR;
		
		addEventListener( TextEvent.EDITED, $changeHandler );
	}
}
}