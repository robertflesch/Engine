/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{

import org.flashapi.swing.*;

public class PanelArrayContainer extends Panel
{
	private var _rootObject:*;

	public function PanelArrayContainer( $rootObject:*, $array:Array, $arrayItemContainer:Class, $widthParam = 300, $heightParam = 400 ) {
		super();
		width = $widthParam;
		height = $heightParam;
		for each ( var item:* in $array ) {
			addElement( new $arrayItemContainer( _rootObject, item ) );
		}
	}
}
}