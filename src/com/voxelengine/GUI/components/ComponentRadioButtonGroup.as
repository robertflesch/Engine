/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import org.flashapi.swing.Box;
import org.flashapi.swing.event.ButtonsGroupEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;
import org.flashapi.swing.plaf.spas.VVUI;

public class ComponentRadioButtonGroup extends Box
{
	public function ComponentRadioButtonGroup( $label:String, $buttonArray:Array, $changeHandler:Function, $initialValue:int, $width:int, $height:int = 40, $padding:int = 10 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = VVUI.DEFAULT_COLOR;
		title = $label;
		borderStyle = BorderStyle.GROOVE;

		var rbg:RadioButtonGroup = new RadioButtonGroup( this );
		var dp:DataProvider = new DataProvider();
		for each ( var o:Object in $buttonArray )
			dp.add( o );

		eventCollector.addEvent( rbg, ButtonsGroupEvent.GROUP_CHANGED, $changeHandler );
		rbg.dataProvider = dp;
		rbg.index = $initialValue;
	}
}
}