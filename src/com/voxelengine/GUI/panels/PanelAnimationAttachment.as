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
import com.voxelengine.worldmodel.animation.AnimationAttachment;


public class PanelAnimationAttachment extends ExpandableBox
{
	private var _ani:Animation;
	private var _aniAttach:AnimationAttachment;
	
	static private const ITEM_HEIGHT:int = 20;
	static private const TITLE:String = "";
	static private const NEW_ITEM_TEXT:String = "Animation Transform";
	public function PanelAnimationAttachment( $ani:Animation, $aniAttach:AnimationAttachment, $widthParam = 250 ) {
		_ani = $ani;
		if ( null == $aniAttach )
			$aniAttach = new AnimationAttachment( AnimationAttachment.DEFAULT_OBJECT );
		_aniAttach = $aniAttach;
		
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
		ebco.showNew = true;
		ebco.paddingTop = 2;
		ebco.width = $widthParam;
		//ebco.backgroundColor = 0x0000ff;
		ebco.showNew = false;
		super( ebco );
	}
	
	//override public function deleteElementCheck( $me:UIMouseEvent ):void {
		//(new Alert( "PanelAnimationAttachment.deleteElementCheck", 350 )).display();
	//}
	
	override public function collapasedInfo():String  {
		if ( _aniAttach )
			return _aniAttach.attachsTo;
		
		return "New Animation Attachment";
	}
	
	override protected function expand():void {
		super.expand();
		
		var cli1:ComponentLabelInput = new ComponentLabelInput( "Attachs To"
										  , function ($e:TextEvent):void { _aniAttach.attachsTo = $e.target.text; setChanged(); }
										  , _aniAttach.attachsTo ? _aniAttach.attachsTo : "Missing Attachment Name"
										  , _itemBox.width )
		_itemBox.addElement( cli1 );
		var cli:ComponentLabelInput = new ComponentLabelInput( "Guid"
										  , function ($e:TextEvent):void { _aniAttach.guid = $e.target.text; setChanged(); }
										  , _aniAttach.guid ? _aniAttach.guid : "Missing Attachment Guid"
										  , _itemBox.width )
		_itemBox.addElement( cli );
		
		var cv3:ComponentVector3DSideLabel;
		cv3 = new ComponentVector3DSideLabel( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniAttach.instanceInfo.positionGet, _itemBox.width, updateVal );
		_itemBox.addElement( cv3 );
		
		cv3 = new ComponentVector3DSideLabel( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniAttach.instanceInfo.rotationGet, _itemBox.width, updateVal );
		_itemBox.addElement( cv3 );
		
		cv3 = new ComponentVector3DSideLabel( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniAttach.instanceInfo.scale, _itemBox.width, updateVal );
		_itemBox.addElement( cv3 );
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