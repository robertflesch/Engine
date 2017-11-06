/**
 * Created by TheBeast on 11/5/2017.
 */
package com.voxelengine.GUI.components {
import com.voxelengine.Globals;
import com.voxelengine.Log;

import org.flashapi.swing.LabelInput;
import org.flashapi.swing.event.TextEvent;

public class VVLabelInput extends LabelInput {
    public function VVLabelInput($title:String = "", $defaultText:String = "", $width:Number = 250) {
        super($title, $defaultText, $width);
        eventCollector.addEvent( this, TextEvent.TEXT_FOCUS_IN, focusIn );
        eventCollector.addEvent( this, TextEvent.TEXT_FOCUS_OUT, focusOut );
    }

    private function focusIn(e:TextEvent):void {
        Log.out( "VVLabelInput.focusIn" );
        Globals.g_textInput = true
    }

    private function focusOut(e:TextEvent):void {
        Log.out( "VVLabelInput.focusOut" );
        Globals.g_textInput = false
    }
}
}


