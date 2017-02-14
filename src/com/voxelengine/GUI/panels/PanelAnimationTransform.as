/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.Alert;
import org.flashapi.swing.Label;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.animation.AnimationTransform;


public class PanelAnimationTransform extends ExpandableBox
{
	static private const NEW_ITEM_TEXT:String = "Animation Transform";
	private var _ani:Animation
	
	public function PanelAnimationTransform( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {
		_ani = $ebco.rootObject

		if ( null == $ebco.item )
			$ebco.item = new AnimationTransform( new Object() );
		
		$ebco.itemBox.showReset = true
		super( $parent, $ebco );
	}
	
	override protected function collapasedInfo():String  {
		if ( _ebco.item ) {
			if ( hasElements()) 
				return _ebco.item.name;
			else
				return _ebco.item.name + " (empty)";
		}
		
		return "New Animation Transform";
	}

	override protected function hasElements():Boolean {
		if ( _ebco.item.hasPosition || _ebco.item.hasRotation || _ebco.item.hasScale || _ebco.item.hasTransform ) 
			return true
		 
		return false
	}
	
	override protected function expand():void {
		super.expand();

		_itemBox.addElement( new Label( _ebco.item.attachmentName, _itemBox.width ) )
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 6 ) )

		var ebcoIb:ExpandableBoxConfigObject = _ebco.clone()
		ebcoIb.width = _itemBox.width
		ebcoIb.title = "initial setting "
		ebcoIb.paddingTop = 7
		_itemBox.addElement( new PanelAnimationTransfromInitData( this, ebcoIb ) )
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 6 ) )

		if ( !_ebco.items ) {
			_ebco.items = new Vector.<*>()
			_ebco.items.push( _ebco.item )
		}
		
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject()
		ebco.rootObject = _ebco.rootObject;
		ebco.items = _ebco.item.transforms as Vector.<*>;
		ebco.itemDisplayObject = PanelModelTransform;
		ebco.itemBox.showNew = true;
		ebco.title = " model transforms ";
		ebco.paddingTop = 7
		ebco.width = _itemBox.width;
		ebco.itemBox.title = " model transforms ";
		ebco.itemBox.newItemText = "New model transform";
		_itemBox.addElement( new PanelModelTransformContainer( this, ebco ) )
	}
	
	override protected function setChanged():void {
		_ani.changed = true;
	}
}
}