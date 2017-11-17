/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.LabelTextArea;
import org.flashapi.swing.LabelTextArea;
import org.flashapi.swing.TextArea;
import org.flashapi.swing.TextInput;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentTextArea extends Box
{
    private var _li:VVTextArea;
	public function ComponentTextArea( $label:String, $changeHandler:Function, $initialValue:String, $width:int, $height:int = 70, $padding:int = 5 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = VVUI.DEFAULT_COLOR;
		title = $label;
		borderStyle = BorderStyle.GROOVE;

		_li = new VVTextArea( $width, $height );
        _li.text = $initialValue;
        _li.addEventListener( TextEvent.EDITED, $changeHandler );
        addElement( _li );
    }

    public function text():String {
        return _li.text;
    }
}
}