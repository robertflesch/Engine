/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.constants.*;

public class ItemBoxConfigObject extends Object
{
	public var borderStyle:String = BorderStyle.GROOVE;
	public var backgroundColor:uint = SpasUI.DEFAULT_COLOR;
	
	public var paddingLeft:int = 4;
	public var paddingTop:int = 5;
	
	public var title:String = "";
	public var showNew:Boolean = false;
	public var showDelete:Boolean = false;
	public var showReset:Boolean = false;
	public var newItemText:String = "New Item";
	public var width:int = 250
	public var height:int = 25
		
	public function ItemBoxConfigObject()	{
	}
	
	public function clone():ItemBoxConfigObject {
		var ibco:ItemBoxConfigObject = new ItemBoxConfigObject()
		ibco.borderStyle		= borderStyle	
		ibco.backgroundColor	= backgroundColor
		ibco.paddingLeft		= paddingLeft
		ibco.paddingTop			= paddingTop
		ibco.title				= title	
		ibco.showNew			= showNew
		ibco.showDelete			= showDelete
		ibco.showReset			= showReset
		ibco.newItemText		= newItemText
		ibco.width				= width
		ibco.height				= height		
		return ibco
	}
}
}