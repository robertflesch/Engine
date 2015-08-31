/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
import org.flashapi.swing.event.UIMouseEvent;


public interface IExpandableItem {
	function collapasedInfo():String;
	function deleteElementCheck( $me:UIMouseEvent ):void;
	function newItemHandler( $me:UIMouseEvent ):void;
}
}