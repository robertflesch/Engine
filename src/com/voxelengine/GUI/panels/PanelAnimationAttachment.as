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
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.UIContainer;	
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;
import com.voxelengine.GUI.components.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.animation.AnimationTransform;
import com.voxelengine.worldmodel.models.types.VoxelModel;


public class PanelAnimationAttachment extends Box
{
	private var _ani:Animation;
	private var _aniXform:AnimationTransform;
	private var _expandCollapse:Button;
	private var _itemBox:Box;
	private var _expanded:Boolean;
	
	private const ITEM_HEIGHT:int = 24;
	public function PanelAnimationAttachment( $ani:Animation, $aniXform:AnimationTransform, $widthParam = 250, $heightParam = 400 ) {
		_ani = $ani;
		_aniXform = $aniXform;
		
		super( $widthParam, $heightParam, BorderStyle.NONE )
		title = $title;
		layout = new AbsoluteLayout();
		padding = 0;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		
		if ( _aniXform ) {
			_expandCollapse = new Button( "+", ITEM_HEIGHT, ITEM_HEIGHT );
			_expandCollapse.padding = 0;
			_expandCollapse.x = 4;
			_expandCollapse.y = 4;
			$evtColl.addEvent( _expandCollapse, UIMouseEvent.RELEASE, changeList );
			addElement( _expandCollapse );
			
			_itemBox = new Box( width - 45 - padding * 2, ITEM_HEIGHT );
			_itemBox.x = 32;
			_itemBox.y = 2;
			_itemBox.padding = 0;
			_itemBox.borderStyle = BorderStyle.NONE;
			_itemBox.backgroundColor = SpasUI.DEFAULT_COLOR;
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
		
		var label:Label = new Label( _aniXform.attachmentName, _itemBox.width - 40 )
		label.backgroundColor = SpasUI.DEFAULT_COLOR;
		_itemBox.addElement( label );
		
		var deleteButton:Button = new Button( "X", 24, 24 );
		deleteButton.y = 0;
		deleteButton.padding = 0;
//		$evtColl.addEvent( deleteButton, UIMouseEvent.RELEASE, changeList );
		_itemBox.addElement( deleteButton );
		
		height = _itemBox.height = 30;
		target.dispatchEvent(new ResizerEvent(ResizerEvent.RESIZE_UPDATE));
	}
	
	private const BUFFER_SIZE:int = 8;
	private function expand():void {
		_itemBox.removeElements();
		_itemBox.layout.orientation = LayoutOrientation.VERTICAL;
		_itemBox.height = 5;
		_expandCollapse.label = "-";
		
		var cli:ComponentLabelInput = new ComponentLabelInput( "Name"
										  , function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
										  , _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
										  , _itemBox.width - 10 )
											
		_itemBox.height += cli.height + BUFFER_SIZE;
		_itemBox.addElement( cli );
		var cv3:ComponentVector3D
		if ( _aniXform.hasPosition ) {
			cv3 = new ComponentVector3D( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, updateVal );
			_itemBox.addElement( cv3 );
			_itemBox.height += cv3.height + BUFFER_SIZE;
		}
		if ( _aniXform.hasRotation ) {
			cv3 = new ComponentVector3D( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, updateVal );
			_itemBox.addElement( cv3 );
			_itemBox.height += cv3.height + BUFFER_SIZE;
		}
		if ( _aniXform.hasScale ) {
			cv3 = new ComponentVector3D( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, updateVal );
			_itemBox.addElement( cv3 );
			_itemBox.height += cv3.height + BUFFER_SIZE;
		}
		_itemBox.height + 10; // need spacer between it and next element
		/*
		var pmt:PanelModelTransform;
		if ( _aniXform.hasTransform ) {
			for each ( var transform:ModelTransform in _aniXform.transforms ) {
				pmt = new PanelModelTransform( _ani, transform, width )
				addElement( pmt );
				_itemBox.height += pmt.height;
			}
		}
		*/
		height = _itemBox.height;
		
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