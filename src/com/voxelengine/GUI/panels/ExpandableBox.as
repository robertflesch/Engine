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
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;

/* This class features a +/- button on the right side
 * and an expandable panel on the right. 
 * The expandable panel can contain more expandable panels
 * allowing for heirarchy to be displayed in a collapable manner
 * the look and feel of the panels can be controlled via the
 * ExpandableBoxConfigObject
 */
public class ExpandableBox extends ResizablePanelVV
{
	private var _expandCollapse:Button;
	private var _expanded:Boolean;
	protected var _itemBox:Box;
	protected var _ebco:ExpandableBoxConfigObject;
	protected var _parent:ExpandableBox;
	
	// classes that inherit this need to override these
	protected function newItemHandler( $me:UIMouseEvent ):void 		{ (new Alert("ExpandableBox.newItemHandler - No function defined")).display();	}
	protected function collapasedInfo():String  					{ return "ExpandableBox.collapasedInfo - No function defined"; }
	
	public function ExpandableBox( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {
		_ebco = $ebco;
		_parent = $parent;
		
		super( _ebco.width, _ebco.itemSize + 2, _ebco.itemBox.borderStyle );
		setConfigInfo();
		layout = new AbsoluteLayout();
		padding = 0;
		autoSize = false;
		
		// This create the expand button
		_expandCollapse = new Button( "+", _ebco.expandButtonSize, _ebco.expandButtonSize );
		_expandCollapse.padding = 0;
		_expandCollapse.x = _ebco.paddingLeft;
		_expandCollapse.y = _ebco.paddingTop;
		$evtColl.addEvent( _expandCollapse, UIMouseEvent.RELEASE, expandOrCollapse );
		addElement( _expandCollapse );
		
		_ebco.itemBox.width = width - 31;
		_itemBox = new ResizablePanelVV( _ebco.itemBox.width, _ebco.itemBox.height, BorderStyle.NONE );
		_itemBox.layout = new AbsoluteLayout();
		_itemBox.autoSize =  false;
		_itemBox.padding = 0;
		_itemBox.x = _ebco.expandButtonSize + (_ebco.paddingLeft * 2);
		_itemBox.y = _ebco.paddingTop;
		_itemBox.backgroundColor = _ebco.itemBox.backgroundColor ;
		addElement( _itemBox );
	
		collapse();
		resizePane( null );
		addEventListener( ResizerEvent.RESIZE_UPDATE, resizePane );		
	}

	public function deleteElementCheck( $me:UIMouseEvent ):void {
		var alert:Alert = new Alert( "Do you really want to delete this " + _ebco.itemBox.title + "?", 350 );
		alert.setLabels( "Yes", "No" );
		alert.alertMode = AlertMode.CHOICE;
		$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
		alert.display();
		
		function alertAction( $ae:AlertEvent ):void {
			if ( AlertEvent.ACTION == $ae.action )
				yesDelete();
			else //if ( AlertEvent.CHOICE == $ae.action );
				doNotDelete()
		}
		
		function doNotDelete():void { /* do nothing */ }
	}
	
	protected function yesDelete():void {
		(new Alert("ExpandableBox.yesDelete - No function defined - override")).display();
	}
	
	public function resetElementCheck( $me:UIMouseEvent ):void {
		var alert:Alert = new Alert( "Do you really want to reset this " + _ebco.itemBox.title + "?", 350 );
		alert.setLabels( "Yes", "No" );
		alert.alertMode = AlertMode.CHOICE;
		$evtColl.addEvent( alert, AlertEvent.BUTTON_CLICK, alertAction );
		alert.display();
		
		function alertAction( $ae:AlertEvent ):void {
			if ( AlertEvent.ACTION == $ae.action )
				resetElement();
			else //if ( AlertEvent.CHOICE == $ae.action );
				doNotReset()
		}
		
		function doNotReset():void { /* do nothing */ }
	}
	
	protected function resetElement():void {
		(new Alert("ExpandableBox.resetElement - No function defined - override")).display();
	}
	
	private function setConfigInfo():void {
		title = _ebco.title;
		backgroundColor = _ebco.itemBox.backgroundColor;
		borderStyle = _ebco.itemBox.borderStyle;
	}
	
	override protected function resizePane( $re:ResizerEvent ):void {
		_itemBox.height = 0;
		for each ( var element:* in _itemBox.getElements() ) {
			//Log.out( "ExpandableBox.resizePane item: " + element + "  element.height: " + element.height + "  paddingTop: " + _ebco.itemBox.paddingTop + "  orientation: " + _itemBox.layout.orientation, Log.WARN );
			if ( LayoutOrientation.VERTICAL == _itemBox.layout.orientation ) {
				element.y = _itemBox.height;
				_itemBox.height += element.height;
			}
			else
				_itemBox.height = Math.max( element.height, _itemBox.height );
		}
		
		height = _itemBox.height + ( _ebco.paddingTop + _ebco.paddingBottom );	
		// Make sure that the min size is larger then the button size plus twice padding
		if ( height < ( _expandCollapse.height + (_ebco.paddingTop + _ebco.paddingBottom) ) )
			height = ( _expandCollapse.height + (_ebco.paddingTop + _ebco.paddingBottom) );
			
		if ( target )
			target.dispatchEvent(new ResizerEvent(ResizerEvent.RESIZE_UPDATE));
	}

	public function changeMode():void {
		if ( _expanded ) {
			_expanded = false;
			collapse();
		}
		else {
			_expanded = true;
			expand();
			if ( _ebco.itemBox.showNew )
				addNewItemButton();
		}
		
		resizePane( null );
	}
	
	private function expandOrCollapse( $me:UIMouseEvent ):void {
		changeMode()
	}
	
	private function addNewItemButton():void {

		var newItemButton:Box = new Box();
		newItemButton.layout = new AbsoluteLayout();
		newItemButton.borderStyle = BorderStyle.GROOVE;
		newItemButton.y = _itemBox.height;
		newItemButton.width = _itemBox.width;
		newItemButton.height = _ebco.itemSize;// + _ebco.itemBox.paddingTop;
		// http://www.colorpicker.com/28BF58
		newItemButton.backgroundColor = 0x28BF58;
		
		var lbl:Label = new Label( _ebco.itemBox.newItemText, _itemBox.width );
		lbl.height = _ebco.itemSize;
		lbl.textAlign = TextAlign.CENTER;
		lbl.verticalAlignment = VerticalAlignment.MIDDLE;
		lbl.y = 1;
		newItemButton.addElement( lbl );
		
		$evtColl.addEvent( lbl, UIMouseEvent.RELEASE, newItemHandler );

		_itemBox.addElement( newItemButton );
		_itemBox.height += newItemButton.height;
	}
	
	// This should be called from the overriding method
	protected function expand():void {
		_itemBox.removeElements();
		_itemBox.layout.orientation = LayoutOrientation.VERTICAL;
		_expandCollapse.label = "-";
	}
	
	protected function hasElements():Boolean {
		return false;
	}
	
	protected function collapse():void {
		_itemBox.removeElements();
		_itemBox.layout.orientation = LayoutOrientation.HORIZONTAL;
		
		_expandCollapse.label = "+";
		
		var label:Label = new Label( collapasedInfo(), _itemBox.width - _ebco.itemSize );
		label.x = 10;
		_itemBox.addElement( label );
		if ( _ebco.itemBox.showDelete ) {
			var deleteButton:Box = new Box();
			deleteButton.x = (_itemBox.width - _ebco.expandButtonSize );
			deleteButton.autoSize = false;
			deleteButton.width = _ebco.expandButtonSize;
			deleteButton.height = _ebco.expandButtonSize;
			deleteButton.padding = 0;
			deleteButton.paddingTop = 1;
			deleteButton.paddingLeft = 4;
			deleteButton.backgroundColor = 0xff0000;
			deleteButton.addElement( new Label( "X" ) );
			$evtColl.addEvent( deleteButton, UIMouseEvent.RELEASE, deleteElementCheck );
			_itemBox.addElement( deleteButton );
		}
		if ( _ebco.itemBox.showReset && hasElements() ) {
			var resetButton:Box = new Box();
			resetButton.x = (_itemBox.width - _ebco.expandButtonSize * 3);
			resetButton.autoSize = false;
			resetButton.width = _ebco.expandButtonSize * 3;
			resetButton.height = _ebco.expandButtonSize;
			resetButton.borderStyle = BorderStyle.RIDGE;
			resetButton.padding = 0;
			resetButton.paddingTop = 1;
			resetButton.paddingLeft = 4;
			resetButton.backgroundColor = 0xff0000;
			var rbLabel:Label = new Label( "Reset", _ebco.expandButtonSize * 3 );
			rbLabel.textAlign = TextAlign.CENTER;
			resetButton.addElement( rbLabel );
			$evtColl.addEvent( resetButton, UIMouseEvent.RELEASE, resetElementCheck );
			_itemBox.addElement( resetButton );
		}
	}
	
	protected function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
		else 											ival++;
		//setChanged();
		$e.target.data.text = ival.toString();
		return ival;
	}
	
	protected function setChanged():void {
		{ (new Alert("ExpandableBox.setChanged - No function defined, MUST override")).display();	}		
	}
	
}
}