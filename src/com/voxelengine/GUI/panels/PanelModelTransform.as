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
	private var _ani:Animation;
	private var _modelXform:ModelTransform;
	
	public function PanelModelTransform( $ani:Animation, $modelXform:ModelTransform, $widthParam = 300, $heightParam = 100 ) {
		_ani = $ani;
		_modelXform = $modelXform;
		
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
		ebco.showNew = true;
		ebco.paddingTop = 2;
		ebco.width = $widthParam;
		//ebco.backgroundColor = 0x0000ff;
		ebco.showNew = false;
		super( ebco );
	}
	
	override public function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "Delete element check ", 350 )).display();
	}
	
	override public function collapasedInfo():String  {
		if ( _modelXform )
			return ModelTransform.typeToString( _modelXform.type );
		
		return "New Model Transform";
	}

	override public function newItemHandler( $me:UIMouseEvent ):void  {
		(new Alert( "newItemHandler", 350 )).display();
		
	}
	
	override protected function expand():void {
		super.expand();
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 10 ) );
		
		var cti1:ComponentTextInput = new ComponentTextInput( "type"
											  , function ($e:TextEvent):void { _modelXform.type = int ( $e.target.text ); setChanged(); }
											  , _modelXform.type ? String( _modelXform.type ) : "Missing type"
											  , width );
		cti1.y = 0;
		_itemBox.addElement( cti1 );
		//_itemBox.height += cti1.height;
		
		var cti2:ComponentTextInput = new ComponentTextInput( "time"
											  , function ($e:TextEvent):void { _modelXform.time = int ( $e.target.text ); setChanged(); }
											  , _modelXform.time ? String( _modelXform.time ) : "Missing time"
											  , width );
		_itemBox.addElement( cti2 );
		//cti2.y = _itemBox.height;
		//_itemBox.height += cti2.height;
		
		var cv3:ComponentVector3DSideLabel = new ComponentVector3DSideLabel( setChanged, "delta", "X: ", "Y: ", "Z: ",  _modelXform.delta, updateVal );
		_itemBox.addElement( cv3 );
		//cv3.y = _itemBox.height;
		//_itemBox.height += cv3.height;
											
		//height = _itemBox.height;
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