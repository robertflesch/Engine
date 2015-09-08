/*==============================================================================
Copyright 2011-2015 Robert Flesch
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
import org.flashapi.swing.containers.UIContainer;	
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.components.*;


public class ExpandableBox extends ResizablePanelVV implements IExpandableItem
{
	private var _expandCollapse:Button;
	private var _expanded:Boolean;
	protected var _itemBox:Box;
	protected var _configObject:ExpandableBoxConfigObject;
	
	private const ITEM_SIZE:int = 25;
	private const EXPAND_BUTTON_HEIGHT:int = 20;
	
	// classes that inherit this need to override these
	public function newItemHandler( $me:UIMouseEvent ):void 		{ (new Alert("ExpandableBox.newItemHandler - No function defined")).display();	}
	public function collapasedInfo():String  					{ return "ExpandableBox.collapasedInfo - No function defined"; }
	public function deleteElementCheck( $me:UIMouseEvent ):void  { (new Alert("ExpandableBox.deleteElementCheck - No function defined")).display(); }
	public function resetElementCheck( $me:UIMouseEvent ):void  { (new Alert("ExpandableBox.resetElementCheck - No function defined")).display(); }
	
	public function ExpandableBox( $configObject:ExpandableBoxConfigObject ) {
		_configObject = $configObject;
		
		super( _configObject.width, ITEM_SIZE + 2, _configObject.itemBox.borderStyle );
		setConfigInfo();
		layout = new AbsoluteLayout();
		padding = 0;
		autoSize = false;
		
		// This create the expand button
		_expandCollapse = new Button( "+", EXPAND_BUTTON_HEIGHT, EXPAND_BUTTON_HEIGHT );
		_expandCollapse.padding = 0;
		_expandCollapse.x = _configObject.itemBox.paddingLeft;
		_expandCollapse.y = _configObject.itemBox.paddingTop;
		$evtColl.addEvent( _expandCollapse, UIMouseEvent.RELEASE, expandOrCollapse );
		addElement( _expandCollapse );
		
		_itemBox = new ResizablePanelVV( width - 31, _configObject.itemBox.height, BorderStyle.NONE );
		_itemBox.layout = new AbsoluteLayout();
		_itemBox.autoSize =  false;
		_itemBox.padding = 0;
		_itemBox.x = EXPAND_BUTTON_HEIGHT + (_configObject.itemBox.paddingLeft * 2);
		_itemBox.y = _configObject.itemBox.paddingTop;
		_itemBox.backgroundColor = _configObject.itemBox.backgroundColor ;
_itemBox.backgroundColor = 0x00ff00;
		addElement( _itemBox );
	
		collapse();
		resizePane( null );
		addEventListener( ResizerEvent.RESIZE_UPDATE, resizePane );		
	}
	
	private function setConfigInfo():void {
		title = _configObject.title;
		backgroundColor = _configObject.itemBox.backgroundColor;
		borderStyle = _configObject.itemBox.borderStyle;
	}
	
	override protected function resizePane( $re:ResizerEvent ):void {
		_itemBox.height = 0;
		for each ( var element:* in _itemBox.getElements() ) {
			//Log.out( "ExpandableBox.resizePane item: " + element + "  element.height: " + element.height + "  paddingTop: " + _configObject.itemBox.paddingTop + "  orientation: " + _itemBox.layout.orientation, Log.WARN );
			if ( LayoutOrientation.VERTICAL == _itemBox.layout.orientation ) {
				element.y = _itemBox.height;
				_itemBox.height += element.height;
			}
			else
				_itemBox.height = Math.max( element.height, _itemBox.height );
		}
		
		height = _itemBox.height + (_configObject.itemBox.paddingTop * 2);	
		if ( height < _configObject.itemBox.height )
			height = _configObject.itemBox.height
			
		if ( target )
			target.dispatchEvent(new ResizerEvent(ResizerEvent.RESIZE_UPDATE));
	}
	
	private function expandOrCollapse( $me:UIMouseEvent ):void {
		if ( _expanded ) {
			_expanded = false;
			collapse();
		}
		else {
			_expanded = true;
			expand();
		}
		
		if ( _configObject.itemBox.showNew )
			addNewItemButton();
			
		resizePane( null );
	}
	
	private function addNewItemButton():void {

		var newItemButton:Box = new Box();
		newItemButton.layout = new AbsoluteLayout();
		newItemButton.borderStyle = BorderStyle.GROOVE;
		newItemButton.y = _itemBox.height;
		newItemButton.width = _itemBox.width;
		newItemButton.height = ITEM_SIZE;// + _configObject.itemBox.paddingTop;
		newItemButton.backgroundColor = 0x00ff00;
		
		var lbl:Label = new Label( _configObject.itemBox.newItemText, _itemBox.width );
		lbl.textAlign = TextAlign.CENTER;
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
		
		var itemCount:String = collapasedInfo();
		var label:Label = new Label( collapasedInfo(), _itemBox.width - ITEM_SIZE );
		label.x = 10;
		_itemBox.addElement( label );
		if ( _configObject.itemBox.showDelete ) {
			var deleteButton:Box = new Box();
			deleteButton.x = (_itemBox.width - EXPAND_BUTTON_HEIGHT );
			deleteButton.autoSize = false;
			deleteButton.width = EXPAND_BUTTON_HEIGHT;
			deleteButton.height = EXPAND_BUTTON_HEIGHT;
			deleteButton.padding = 0;
			deleteButton.paddingTop = 1;
			deleteButton.paddingLeft = 4;
			deleteButton.backgroundColor = 0xff0000;
			deleteButton.addElement( new Label( "X" ) );
			$evtColl.addEvent( deleteButton, UIMouseEvent.RELEASE, deleteElementCheck );
			_itemBox.addElement( deleteButton );
		}
		if ( _configObject.itemBox.showReset && hasElements() ) {
			var resetButton:Box = new Box();
			resetButton.x = (_itemBox.width - EXPAND_BUTTON_HEIGHT * 3);
			resetButton.autoSize = false;
			resetButton.width = EXPAND_BUTTON_HEIGHT * 3;
			resetButton.height = EXPAND_BUTTON_HEIGHT;
			resetButton.borderStyle = BorderStyle.RIDGE
			resetButton.padding = 0;
			resetButton.paddingTop = 1;
			resetButton.paddingLeft = 4;
			resetButton.backgroundColor = 0xff0000;
			resetButton.addElement( new Label( "  Reset" ) );
			$evtColl.addEvent( resetButton, UIMouseEvent.RELEASE, resetElementCheck );
			_itemBox.addElement( resetButton );
		}

	}
}
}