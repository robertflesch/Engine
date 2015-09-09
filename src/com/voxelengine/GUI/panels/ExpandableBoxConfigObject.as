/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.Box;

public class ExpandableBoxConfigObject extends Object
{
	public var rootObject:*
	public var items:Vector.<*>
	public var item:Box
	public var itemDisplayObject:Class
	public var title:String
	public var width:int = 200	
	public var itemBox:ItemBoxConfigObject = new ItemBoxConfigObject()
		
	public function ExpandableBoxConfigObject()	{
	}
}
}