/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI {
import flash.display.BitmapData;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.event.*;

import org.flashapi.swing.plaf.spas.VVUI;

public class VVBox extends Box
{
	private var _boxHelp:BoxHelp;
	
	public function VVBox( $widthParam:Number, $heightParam:Number = 100, $borderStyle:String = BorderStyle.GROOVE ) {
		super( $widthParam, $heightParam, $borderStyle );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		backgroundColor = VVUI.DEFAULT_COLOR;
	}
	
	protected function onRemoved( event:UIOEvent ):void {
		eventCollector.removeAllEvents();
	}
	
	public function setHelp( $text:String ):void {
		_boxHelp = new BoxHelp( $text );
		eventCollector.addEvent( this, UIMouseEvent.ROLL_OVER, function (e:UIMouseEvent):void { _boxHelp.display(); } );
		eventCollector.addEvent( this, UIMouseEvent.ROLL_OUT, function (e:UIMouseEvent):void { _boxHelp.remove(); } );
	}

	static public function drawScaled(obj:BitmapData, destWidth:int, destHeight:int, $hasTransparency:Boolean = false ):BitmapData {
		if ( null == obj )
				return null;
		var m:Matrix = new Matrix();
		m.scale(destWidth/obj.width, destHeight/obj.height);
		var bmpd:BitmapData = new BitmapData(destWidth, destHeight, $hasTransparency ,0x000000ff);
		bmpd.draw( obj, m );
		return bmpd;
	}

}
}