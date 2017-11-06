/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {

import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentLabelInput extends VVLabelInput
{
	public function ComponentLabelInput( $label:String, $changeHandler:Function, $initialValue:String, $width:int )
	{
		super( $label, $initialValue, $width );
		backgroundColor = VVUI.DEFAULT_COLOR;
		
		addEventListener( TextEvent.EDITED, $changeHandler );
	}
	
	override public function get height () : Number { return super.height + 5; }
}
}