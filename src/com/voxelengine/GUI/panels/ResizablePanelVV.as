/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.Box;
import org.flashapi.swing.event.ResizerEvent;

public class ResizablePanelVV extends Box
{
	// This just adds a RESIZE_UPDATE relay to box, So that parent object can respond
	public function ResizablePanelVV( $widthParam:int, $heightParam:int, $borderStyleParam:String ) {
		super( $widthParam, $heightParam, $borderStyleParam );
		addEventListener( ResizerEvent.RESIZE_UPDATE, resizePane );		
	}
	
	protected function resizePane( $re:ResizerEvent ):void {
		if ( target )
			target.dispatchEvent( $re );
	}
	
}
}