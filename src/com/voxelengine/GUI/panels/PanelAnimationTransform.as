/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.GUI.animation.WindowAnimationDetail;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.animation.AnimationAttachment;
import com.voxelengine.worldmodel.animation.AnimationTransform;
import com.voxelengine.worldmodel.MemoryManager;
import com.voxelengine.worldmodel.models.ModelTransform;
import flash.display.Bitmap;
import org.flashapi.swing.wtk.WindowButtonClose;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.UIContainer;	
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.models.types.VoxelModel;


public class PanelAnimationTransform extends Box
{
	private var _ani:Animation;
	private var _aniXform:AnimationTransform;
	private var _expandCollapse:Button;
	private var _itemBox:Box;
	private var _expanded:Boolean;
	
	private const ITEM_HEIGHT:int = 20;
	public function PanelAnimationTransform( $ani:Animation, $aniXform:AnimationTransform, $widthParam = 250, $heightParam = 400 ) {
		_ani = $ani;
		_aniXform = $aniXform;
		
		super( $widthParam, $heightParam, BorderStyle.NONE )
		layout = new AbsoluteLayout();
		padding = 0;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		title = $title;
		padding = 0;
		
		if ( _aniXform ) {
			_expandCollapse = new Button( "+", ITEM_HEIGHT, ITEM_HEIGHT );
			_expandCollapse.padding = 0;
			_expandCollapse.x = 4;
			_expandCollapse.y = 0;
			$evtColl.addEvent( _expandCollapse, UIMouseEvent.RELEASE, changeList );
			addElement( _expandCollapse );
			
			_itemBox = new Box();
			_itemBox.autoSize = false;
			_itemBox.width = width - 45 - padding * 2 
			_itemBox.height = ITEM_HEIGHT + 12;
			_itemBox.x = 32;
			_itemBox.y = 0;
			_itemBox.padding = 1;
			_itemBox.borderStyle = BorderStyle.NONE;
//			_itemBox.backgroundColor = SpasUI.DEFAULT_COLOR;
			_itemBox.backgroundColor = 0x00ff00;

			addElement( _itemBox );
			collapse();
		}
		else {
			height = ITEM_HEIGHT + 8;
			var newItemButton:Button = new Button( "New Animation on child model", width - 20, ITEM_HEIGHT );
			newItemButton.x = 4;
			newItemButton.y = 4;
			$evtColl.addEvent( newItemButton, UIMouseEvent.RELEASE, newItemHandler );
			newItemButton.color = 0x00FF00;
			addElement( newItemButton );
		}
		addEventListener( ResizerEvent.RESIZE_UPDATE, resizePane );		
	}
	
	private function newItemHandler( $me:UIMouseEvent ):void  {
		
	}
	
	private function changeList( $me:UIMouseEvent ):void {
		if ( _expanded ) {
			_expanded = false;
			collapse();
		}
		else {
			_expanded = true;
			expand();
		}
	}
	
	private function collapse():void {
		
		_itemBox.removeElements();
		_itemBox.layout.orientation = LayoutOrientation.HORIZONTAL;
		
		_expandCollapse.label = "+";
		
		var label:Label = new Label( _aniXform.attachmentName, _itemBox.width - (ITEM_HEIGHT + 5) );
		_itemBox.addElement( label );
		
		var deleteButton:Box = new Box();
		deleteButton.autoSize = false;
		deleteButton.width = ITEM_HEIGHT;
		deleteButton.height = ITEM_HEIGHT;
		deleteButton.padding = 0;
		deleteButton.paddingLeft = 3;
		deleteButton.backgroundColor = 0xff0000;
		deleteButton.addElement( new Label( "X" ) );
		$evtColl.addEvent( deleteButton, UIMouseEvent.RELEASE, deleteElementCheck );
		_itemBox.addElement( deleteButton );
		
		resizePane( null );
	}
	
	private function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "Delete element check ", 350 )).display();
	}
	
	private function expand():void {
		_itemBox.removeElements();
		_itemBox.layout.orientation = LayoutOrientation.VERTICAL;
		_itemBox.height = 5;
		_expandCollapse.label = "-";
		
		var cli:ComponentLabelInput = new ComponentLabelInput( "Name"
										  , function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
										  , _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
										  , _itemBox.width - 10 )
											
		_itemBox.height += cli.height;
		_itemBox.addElement( cli );
		var cv3:ComponentVector3D
		if ( _aniXform.hasPosition ) {
			cv3 = new ComponentVector3D( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, updateVal );
			_itemBox.addElement( cv3 );
		}
		if ( _aniXform.hasRotation ) {
			cv3 = new ComponentVector3D( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, updateVal );
			_itemBox.addElement( cv3 );
		}
		if ( _aniXform.hasScale ) {
			cv3 = new ComponentVector3D( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, updateVal );
			_itemBox.addElement( cv3 );
		}
		_itemBox.height + 5; // need spacer between it and next element

		_itemBox.addElement( new PanelVectorContainer( _ani
		                                    , _aniXform.transforms as Vector.<*>
											, "transforms on child model"
											, PanelModelTransform, _itemBox.width ) );
		
		height = _itemBox.height;
		resizePane( null );
	}
	
	private static const BUFFER:int = 10;
	public function resizePane( $re:ResizerEvent ):void {
		_itemBox.height = 0;
		
		for each ( var element:* in _itemBox.getElements() ) {
			Log.out( "PanelAnimationTransform.resizePane item: " + element );
			if ( LayoutOrientation.VERTICAL == _itemBox.layout.orientation )
				_itemBox.height += element.height + BUFFER;
			else	
				_itemBox.height = Math.max( element.height, _itemBox.height );
		}
		
		Log.out( "PanelAnimationTransform.resizePane height: " + _itemBox.height );
		
		if ( _itemBox.height < 26 )
			height = 26
		else	
			height = _itemBox.height + 5;
			
		target.dispatchEvent(new ResizerEvent(ResizerEvent.RESIZE_UPDATE));
	}
	

	
	
	private function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
		else 											ival++;
		setChanged();
		$e.target.data.text = ival.toString();
		return ival;
	}
	
	
	private function setChanged():void {
		_ani.changed = true;
	}
}
}