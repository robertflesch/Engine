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


public class PanelAnimationTransform extends PanelBase
{
	private var _ani:Animation;
	private var _aniXform:AnimationTransform;
	
	public function PanelAnimationTransform( $ani:Animation, $aniXform:AnimationTransform, $widthParam = 300, $heightParam = 400 ) {
		super( $parent, $widthParam, $heightParam );
		_ani = $ani;
		_aniXform = $aniXform;
		addElement( new ComponentTextInput( "attachmentName"
										  , function ($e:TextEvent):void { _aniXform.attachmentName = $e.target.text; setChanged(); }
										  , _aniXform.attachmentName ? _aniXform.attachmentName : "Missing Attachment Name"
										  , width ) );
		if ( _aniXform.hasPosition )
			addElement( new ComponentVector3D( setChanged, "location", "X: ", "Y: ", "Z: ",  _aniXform.position, updateVal ) );
		if ( _aniXform.hasRotation )
			addElement( new ComponentVector3D( setChanged, "rotation", "X: ", "Y: ", "Z: ",  _aniXform.rotation, updateVal ) );
		if ( _aniXform.hasScale )
			addElement( new ComponentVector3D( setChanged, "scale", "X: ", "Y: ", "Z: ",  _aniXform.scale, updateVal ) );
		if ( _aniXform.hasTransform ) {
			for each ( var transform:ModelTransform in _aniXform.transforms ) {
				addElement( new PanelModelTransform( _ani, transform ) );
			}
		}
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