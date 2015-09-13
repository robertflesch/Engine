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
	public var rootObject:*		// The root of the object, needed to be marked as changed
	public var items:Vector.<*> // The branch of the tree
	public var item:*			// The leaf being operated on.
	public var itemDisplayObject:Class
	public var title:String
	public var width:int = 200	
	public var itemBox:ItemBoxConfigObject = new ItemBoxConfigObject()
	public var paddingLeft:int = 4;
	public var paddingTop:int = 5;
	public var itemSize:int = 25;
	public var expandButtonSize:int = 20;

		
	public function ExpandableBoxConfigObject()	{
	}
	
	public function clone():ExpandableBoxConfigObject {
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.rootObject			= rootObject			
		ebco.items				= items				
		ebco.item				= item				
		ebco.itemDisplayObject	= itemDisplayObject	
		ebco.title				= title				
		ebco.width				= width				
		ebco.itemBox			= itemBox.clone()			
		ebco.paddingLeft		= paddingLeft
		ebco.paddingTop			= paddingTop
		ebco.itemSize			= itemSize
		ebco.expandButtonSize	= expandButtonSize
		return ebco
	}
}
}