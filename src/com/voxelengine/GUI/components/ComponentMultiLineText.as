/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.Text;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentMultiLineText extends Box {
    public function ComponentMultiLineText( $label:String, $value:String, $width:int, $height:int = 32, $padding:int = 8 ) {
        super( $width, $height, BorderStyle.GROOVE );
        padding = $padding;
        backgroundColor = VVUI.DEFAULT_COLOR;
        title = $label;
        var t:Text = new Text( $width, $height - 8 );
        t.text = $value;
        addElement( t );
    }
}
}

