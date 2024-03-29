/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Container;
import org.flashapi.swing.Label;
import org.flashapi.swing.plaf.spas.VVUI;
import org.flashapi.swing.constants.*;

public class ComponentLabelSide extends Container
{
	public function ComponentLabelSide( $label:String, $initialValue:String, $width:int, $height:int = 25, $padding:int = 3 )
	{
		super( $width, $height );
	
		layout.orientation = LayoutOrientation.HORIZONTAL;
		padding = $padding;
		backgroundColor = VVUI.DEFAULT_COLOR;
		
		addElement( new Label( $label, ($width - 20) * 0.40 ) );
        if ( !$initialValue )
            addElement( new Label( "UNDEFINED", ($width - 20) * 0.60 ) );
		else
			addElement( new Label( $initialValue, ($width - 20) * 0.60 ) );
	}
}
}