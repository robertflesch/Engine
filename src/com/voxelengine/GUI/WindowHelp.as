/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.events.HelpEvent;

import org.flashapi.swing.*;
import org.flashapi.swing.event.UIOEvent;

import com.voxelengine.Globals;

public class WindowHelp extends Popup
{
	private var _textArea:TextArea = new TextArea();

	static public function init():void {
		HelpEvent.add( HelpEvent.CREATE, function( $he:HelpEvent ):void { new WindowHelp( $he.textFileName() )} );
	}

	public function WindowHelp( $fileName:String ) {
		super("Help");
		//autoSize = true;
		width = 600;
		height = 600;
		shadow = true;
		_textArea.width = 600;
		_textArea.height = 600;
		_textArea.editable = false;
		_textArea.loadText( Globals.appPath + "assets/help/" + $fileName );
		addElement(_textArea);
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		display(30, 30);
	}

	private function onRemoved( event:UIOEvent ):void {
		HelpEvent.create( HelpEvent.CLOSED );
	}

}
}