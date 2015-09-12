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
	private var _ani:Animation
	private var _mt:ModelTransform
	
	//public function PanelModelTransform( $ani:Animation, $modelXform:ModelTransform, $widthParam = 300, $heightParam = 100 ) {
	public function PanelModelTransform( $ebco:ExpandableBoxConfigObject ) {		
		_ani = $ebco.rootObject
		_mt = $ebco.item
		if ( null == _mt ) {
			$ebco.item = _mt = ModelTransform.defaultObject();
			$ebco.items.push( _mt );
		}
		
		$ebco.itemBox.showNew = false;
		$ebco.itemBox.paddingTop = 2;
		super( $ebco );
	}
	
	override protected function yesDelete():void {
		// now I need to iterate thru the items, and find the right one to delete
		var itemSig:String = _mt.toString();
		var mts:Vector.<ModelTransform> = _ebco.items as Vector.<ModelTransform>
		for ( var i:int; i < mts.length; i++ ) {
			var mt:ModelTransform = mts[i];
			// don't add the deleted item to the list
			if ( mt.toString() == itemSig ) {
				mts.splice( i, 1 )
			}
		}
		collapse();
	}
	
	override protected function collapasedInfo():String  {
		if ( _mt ) {
			if ( ModelTransform.INVALID == _mt.type )
				return "No transforms "
			return ModelTransform.typeToString( _mt.type ) + "  " + _mt.deltaAsString();
		}
		
		return "New Model Transform";
	}

	override protected function hasElements():Boolean {
		if ( 0 < _mt.delta.length ) 
			return true
		 
		return false
	}
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 4 ) );
		
		_itemBox.addElement( new ComponentComboBoxWithLabel( "Transform type", typeChanged, ModelTransform.typeToString( _mt.type ), ModelTransform.typesList(), _itemBox.width ) )
		_itemBox.addElement( new ComponentLabelInput( "time (ms)"
											  , function ($e:TextEvent):void { _mt.time = int ( $e.target.text ); setChanged(); }
											  , _mt.time ? String( _mt.time ) : "Missing time"
											  , _itemBox.width ) )
											  
		_itemBox.addElement( new ComponentVector3DSideLabel( setChanged, "delta", "X: ", "Y: ", "Z: ",  _mt.delta, _itemBox.width, updateVal ) )
	}
	
	private function typeChanged( $le:ListEvent ): void {
		var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex )
		 _mt.type = ModelTransform.stringToType( li.value )
		 _ani.changed = true;
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
		_ani.changed = true;
	}
}
}