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


public class PanelModelTransform extends PanelBase
{
	private var _ani:Animation;
	private var _aniXform:ModelTransform;
	
	public function PanelModelTransform( $ani:Animation, $aniXform:ModelTransform, $widthParam = 300, $heightParam = 100 ) {
		super( $parent, $widthParam, $heightParam );
		_ani = $ani;
		_aniXform = $aniXform;
		addElement( new ComponentTextInput( "type"
										  , function ($e:TextEvent):void { _aniXform.type = int ( $e.target.text ); setChanged(); }
										  , _aniXform.type ? String( _aniXform.type ) : "Missing type"
										  , width ) );
		addElement( new ComponentTextInput( "time"
										  , function ($e:TextEvent):void { _aniXform.time = int ( $e.target.text ); setChanged(); }
										  , _aniXform.time ? String( _aniXform.time ) : "Missing time"
										  , width ) );
		addElement( new ComponentVector3D( setChanged, "delta", "X: ", "Y: ", "Z: ",  _aniXform.delta, updateVal ) );
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