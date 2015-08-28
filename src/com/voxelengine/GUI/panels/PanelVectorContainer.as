/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.GUI.*;

public class PanelVectorContainer extends Box {
	private var _vector:Vector.<*>;
	private var _itemDisplayObject:Class;
	private var _rootObject:*;
	private var _expanded:Boolean;
	private var _title:String;
	private var _expandCollpase:Button;
	private var _scrollPane:ScrollPane;
	
	// Note: item in vector needs to have a "name" method
	public function PanelVectorContainer( $rootObject:*, $vector:Vector.<*>, $title:String, $itemDisplayObject:Class, $widthParam = 300, $heightParam = 400 ) {
		_title = $title;
		_vector = $vector;
		_itemDisplayObject = $itemDisplayObject;
		_rootObject = $rootObject;
		
		super( $widthParam, $heightParam, BorderStyle.GROOVE )
		layout = new AbsoluteLayout();
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = $title;
		padding = 0;
		paddingTop = 8;
		
		_expandCollpase = new Button( "+", 24, 24 );
		_expandCollpase.padding = 0;
		_expandCollpase.x = 4;
		_expandCollpase.y = 8;
		$evtColl.addEvent( _expandCollpase, UIMouseEvent.RELEASE, changeList );
		addElement( _expandCollpase );
		
		_scrollPane = new ScrollPane();
		_scrollPane.scrollPolicy = ScrollPolicy.NONE;
		_scrollPane.width = width - _expandCollpase.width - 10;
		_scrollPane.height = 24;
		_scrollPane.layout.orientation = LayoutOrientation.VERTICAL;
		_scrollPane.x = 32;
		_scrollPane.y = 9;
		_scrollPane.padding = 0;
		//_scrollPane.borderStyle = BorderStyle.GROOVE;
		//_scrollPane.backgroundColor = SpasUI.DEFAULT_COLOR;
		addElement( _scrollPane );
		
		collapse();
		addEventListener( ResizerEvent.RESIZE_UPDATE, resizePane );		
	}
	
	
	private function changeList( $me:UIMouseEvent ):void {
		if ( _expanded )
			collapse();
		else
			expand();
	}
	
	private function collapse():void {
		_expanded = false;
		_scrollPane.removeElements();
		_expandCollpase.label = "+";
		var label:Label = new Label( " (" + _vector.length + ")" )
		label.backgroundColor = SpasUI.DEFAULT_COLOR;
		_scrollPane.addElement( label );
		resizePane( null );
	}
	
	private function expand():void {
		_expanded = true;
		_scrollPane.removeElements();
		_scrollPane.scrollPolicy = ScrollPolicy.NONE;
		_expandCollpase.label = "-";
		
		for each ( var item:* in _vector )
			_scrollPane.addElement( new _itemDisplayObject( _rootObject, item, (_scrollPane.width - 10) ) );
		
		// Add an emtpy object to generate a new button
		_scrollPane.addElement( new _itemDisplayObject( _rootObject, null, (_scrollPane.width - 10) ) );
		
		resizePane( null );
	}
	
	public function resizePane( $re:ResizerEvent ):void {
		_scrollPane.height = 0;
		for each ( var element:* in _scrollPane.getElements() ) {
			//Log.out( "PanelVectorContainer.resizePane - element.height: " + element.height, Log.WARN );
			_scrollPane.height += element.height;
		}
		
		if ( _scrollPane.height < 26 )
			height = 36
		else	
			height = _scrollPane.height + 10;
	}
}
}