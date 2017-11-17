/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.components {
import com.voxelengine.Globals;
import com.voxelengine.Log;

import flash.events.FocusEvent;

import org.flashapi.swing.TextArea;
import org.flashapi.swing.event.TextEvent;

public class VVTextArea extends TextArea {
    public function VVTextArea( $widthInput:int, $heightInput:int ) {
        super( $widthInput, $heightInput );
        eventCollector.addEvent( this, FocusEvent.FOCUS_IN, focusIn );
        eventCollector.addEvent( this, FocusEvent.FOCUS_OUT, focusOut );

    }

    private function focusIn(e:FocusEvent):void {
        //Log.out( "VVTextInput.focusIn" );
        Globals.g_textInput = true
    }

    private function focusOut(e:FocusEvent):void {
        //Log.out( "VVTextInput.focusOut" );
        Globals.g_textInput = false
    }
}
}