/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import com.voxelengine.Log;
import org.flashapi.swing.Box;
import org.flashapi.swing.TextInput;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.plaf.spas.VVUI;;
import com.voxelengine.Globals;
public class VVTextInput extends TextInput
{
	public function VVTextInput( $label:String, $width:int )
	{
		super( $label, $width );
		
		eventCollector.addEvent( this, TextEvent.TEXT_FOCUS_IN, focusIn );
		eventCollector.addEvent( this, TextEvent.TEXT_FOCUS_OUT, focusOut );
	}
	
	private function focusIn(e:TextEvent):void {
		Log.out( "VVTextInput.focusIn" )
		Globals.g_textInput = true
	}
	
	private function focusOut(e:TextEvent):void {
		Log.out( "VVTextInput.focusOut" )
		Globals.g_textInput = false
	}
}
}