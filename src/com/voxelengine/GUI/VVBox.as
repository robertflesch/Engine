/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI {
import org.flashapi.swing.*;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.event.*;

import com.voxelengine.Globals;

public class VVBox extends Box
{
	private var _boxhelp:BoxHelp;
	
	public function VVBox( $widthParam:Number, $heightParam:Number, $borderStyle:String, $help:String = "" )
	{
		super( $widthParam, $heightParam, $borderStyle );
		_boxhelp = new BoxHelp( $help );
		eventCollector.addEvent( this, UIMouseEvent.ROLL_OVER, function (e:UIMouseEvent):void { _boxhelp.display(); } );
		eventCollector.addEvent( this, UIMouseEvent.ROLL_OUT, function (e:UIMouseEvent):void { _boxhelp.remove(); } );					
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}		
	
	protected function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeAllEvents();
	}
}
}