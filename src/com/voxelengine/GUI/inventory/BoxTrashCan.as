/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {
	
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.GUI.*;

public class BoxTrashCan extends VVBox
{
	public function BoxTrashCan( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		autoSize = false;
		dragEnabled = true;
	}	
}	

}