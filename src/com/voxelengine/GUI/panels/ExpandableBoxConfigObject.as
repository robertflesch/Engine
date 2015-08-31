/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.constants.*;

public class ExpandableBoxConfigObject extends Object
{
	public var width:int = 250;
	public var borderStyle:String = BorderStyle.GROOVE;
	public var backgroundColor:uint = SpasUI.DEFAULT_COLOR;
	public var paddingLeft:int = 4;
	public var paddingTop:int = 6;
	public var title:String = "";
	public var showNew:Boolean = true;
	public var newItemText:String = "New Item";
	public var showDelete:Boolean = true;
		
	public function ExpandableBoxConfigObject()	{
	}
}
}