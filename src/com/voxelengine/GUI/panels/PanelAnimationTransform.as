/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.Alert;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.animation.AnimationTransform;


public class PanelAnimationTransform extends ExpandableBox
{
	private var _ani:Animation;
	private var _aniXform:AnimationTransform;
	
	static private const NEW_ITEM_TEXT:String = "Animation Transform";
	public function PanelAnimationTransform( $ani:Animation, $aniXform:AnimationTransform, $widthParam = 250 ) {
		_ani = $ani;
		if ( null == $aniXform )
			$aniXform = new AnimationTransform( AnimationTransform.DEFAULT_OBJECT );
		_aniXform = $aniXform;
		
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.itemBox.showNew = false
		ebco.itemBox.showDelete = false
		ebco.itemBox.showReset = true
		ebco.itemBox.paddingTop = 2
		ebco.width = $widthParam
		ebco.itemBox.height = 25
		//ebco.backgroundColor = 0x0000ff;
		super( ebco );
		//autoSize = false;
		//width = $widthParam;
		//height = 25
	}
	
	override public function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "PanelAnimationTransform.deleteElementCheck", 350 )).display();
	}
	
	override public function collapasedInfo():String  {
		if ( _aniXform ) {
			if ( hasElements() ) 
				return _aniXform.name;
			else
				return _aniXform.name + " (empty)";
		}
		
		return "New Animation Transform";
	}

	override public function newItemHandler( $me:UIMouseEvent ):void  {
		(new Alert( "PanelAnimationTransform.newItemHandler", 350 )).display();
	}
	
	override protected function hasElements():Boolean {
		if ( _aniXform.hasPosition || _aniXform.hasRotation || _aniXform.hasScale || _aniXform.hasTransform ) 
			return true
		 
		return false
	}
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.addElement( new ComponentLabelInput( "Name"
													, function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
													, _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
													, _itemBox.width ) );
													
		_itemBox.addElement( new ComponentVector3DSideLabel( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, _itemBox.width, updateVal ) );
		_itemBox.addElement( new ComponentVector3DSideLabel( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, _itemBox.width, updateVal ) );
		_itemBox.addElement( new ComponentVector3DSideLabel( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, _itemBox.width, updateVal ) );
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 6 ) )

		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.rootObject = _ani
		ebco.items = _aniXform.transforms as Vector.<*>
		ebco.itemDisplayObject = PanelModelTransform
		ebco.itemBox.showNew = true
		ebco.title = "transforms"
		ebco.width = _itemBox.width
		ebco.itemBox.newItemText = "New Transform"
		_itemBox.addElement( new PanelVectorContainer( ebco ) )
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