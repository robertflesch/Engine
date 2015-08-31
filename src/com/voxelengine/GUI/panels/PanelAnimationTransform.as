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


public class PanelAnimationTransform extends ExpandableBox
{
	private var _ani:Animation;
	private var _aniXform:AnimationTransform;
	
	static private const ITEM_HEIGHT:int = 20;
	static private const TITLE:String = "";
	static private const NEW_ITEM_TEXT:String = "Animation Transform";
	public function PanelAnimationTransform( $ani:Animation, $aniXform:AnimationTransform, $widthParam = 250 ) {
		_ani = $ani;
		_aniXform = $aniXform;
		
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
		ebco.showNew = true;
		ebco.paddingTop = 2;
		//ebco.paddingLeft = 4;
		ebco.width = $widthParam;
		//ebco.backgroundColor = 0x0000ff;
		ebco.showNew = false;
		super( ebco );
	}
	
	override public function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "Delete element check ", 350 )).display();
	}
	
	override public function collapasedInfo():String  {
		if ( _aniXform )
			return _aniXform.name;
		
		return "New Animation Transform";
	}

	override public function newItemHandler( $me:UIMouseEvent ):void  {
		(new Alert( "newItemHandler", 350 )).display();
	}
	
	override protected function expand():void {
		super.expand();
		
		var cli:ComponentLabelInput = new ComponentLabelInput( "Name"
										  , function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
										  , _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
										  , _itemBox.width )
											
		_itemBox.addElement( cli );
		var cv3:ComponentVector3DSideLabel
		if ( _aniXform.hasPosition ) {
			cv3 = new ComponentVector3DSideLabel( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, updateVal );
			_itemBox.addElement( cv3 );
		}
		if ( _aniXform.hasRotation ) {
			cv3 = new ComponentVector3DSideLabel( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, updateVal );
			_itemBox.addElement( cv3 );
		}
		if ( _aniXform.hasScale ) {
			cv3 = new ComponentVector3DSideLabel( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, updateVal );
			_itemBox.addElement( cv3 );
		}
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 10 ) )

		_itemBox.addElement( new PanelVectorContainer( "transforms"
											, _ani
		                                    , _aniXform.transforms as Vector.<*>
											, PanelModelTransform
											, "New Transform Child"
											, _itemBox.width ) );
	}
	
	protected function expandOld():void {
		super.expand();
		
		var cli:ComponentLabelInput = new ComponentLabelInput( "Name"
										  , function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
										  , _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
										  , _itemBox.width - 10 )
											
		cli.y = 0;
		_itemBox.addElement( cli );
		_itemBox.height += cli.height;
		var cv3:ComponentVector3D
		if ( _aniXform.hasPosition ) {
			cv3 = new ComponentVector3D( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, updateVal );
			_itemBox.addElement( cv3 );
			cv3.y = _itemBox.height;
			_itemBox.height += cv3.height;
		}
		if ( _aniXform.hasRotation ) {
			cv3 = new ComponentVector3D( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, updateVal );
			_itemBox.addElement( cv3 );
			cv3.y = _itemBox.height;
			_itemBox.height += cv3.height;
		}
		if ( _aniXform.hasScale ) {
			cv3 = new ComponentVector3D( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, updateVal );
			_itemBox.addElement( cv3 );
			cv3.y = _itemBox.height;
			_itemBox.height += cv3.height;
		}
/*
		_itemBox.addElement( new PanelVectorContainer( "transforms on child model"
											, _ani
		                                    , _aniXform.transforms as Vector.<*>
											, PanelModelTransform
											, _itemBox.width ) );
	*/	
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