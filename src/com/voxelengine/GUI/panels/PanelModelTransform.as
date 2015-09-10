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

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.UIContainer;	

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.models.types.VoxelModel;


public class PanelModelTransform extends ExpandableBox
{
	private var _cbType:ComboBox  = new ComboBox()	
	
	//public function PanelModelTransform( $ani:Animation, $modelXform:ModelTransform, $widthParam = 300, $heightParam = 100 ) {
	public function PanelModelTransform( $ebco:ExpandableBoxConfigObject ) {		
		if ( null == $ebco.item ) {
			$ebco.item = ModelTransform.defaultObject();
		}
		
		$ebco.itemBox.showNew = false;
		$ebco.itemBox.paddingTop = 2;
		super( $ebco );
	}
	
	override public function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "Delete element check ", 350 )).display();
	}
	
	override public function collapasedInfo():String  {
		if ( _ebco.item ) {
			if ( ModelTransform.INVALID == _ebco.item.type )
				return "No transforms "
			return ModelTransform.typeToString( _ebco.item.type );
		}
		
		return "New Model Transform";
	}

	override public function newItemHandler( $me:UIMouseEvent ):void  {
		(new Alert( "newItemHandler", 350 )).display();
	}
	
	override protected function hasElements():Boolean {
		if ( 0 < _ebco.item.delta.length ) 
			return true
		 
		return false
	}
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 10 ) );
		
		_itemBox.addElement( new ComponentComboBoxWithLabel( "Transform type", typeChanged, ModelTransform.typeToString( _ebco.item.type ), ModelTransform.typesList(), _itemBox.width ) )
		_itemBox.addElement( new ComponentLabelInput( "time (ms)"
											  , function ($e:TextEvent):void { _ebco.item.time = int ( $e.target.text ); setChanged(); }
											  , _ebco.item.time ? String( _ebco.item.time ) : "Missing time"
											  , _itemBox.width ) )
											  
		_itemBox.addElement( new ComponentVector3DSideLabel( setChanged, "delta", "X: ", "Y: ", "Z: ",  _ebco.item.delta, _itemBox.width, updateVal ) )
	}
	
	private function typeChanged( $le:ListEvent ): void {
		var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex )
		 _ebco.item.type = ModelTransform.stringToType( li.value )
		 _ebco.rootObject.changed = true;
	}
	
	//////////////////////////////
	
	private function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
		else 											ival++;
		setChanged();
		$e.target.data.text = ival.toString();
		return ival;
	}
	
	
	private function setChanged():void {
		_ebco.rootObject.changed = true;
	}
}
}