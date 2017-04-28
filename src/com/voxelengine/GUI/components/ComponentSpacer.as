/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentSpacer extends Box
{
	public function ComponentSpacer( $width:int, $height:int = 10, $padding:int = 0 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = VVUI.DEFAULT_COLOR;

		borderStyle = BorderStyle.NONE;
	}
}
}