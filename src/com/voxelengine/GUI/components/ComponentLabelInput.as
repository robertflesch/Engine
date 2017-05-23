/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentLabelInput extends LabelInput
{
	public function ComponentLabelInput( $label:String, $changeHandler:Function, $initialValue:String, $width:int, $height:int = 20, $padding:int = 15 )
	{
		super( $label, $initialValue, $width );
		backgroundColor = VVUI.DEFAULT_COLOR;
		
		addEventListener( TextEvent.EDITED, $changeHandler );
	}
	
	override public function get height () : Number { return super.height + 5; }
}
}