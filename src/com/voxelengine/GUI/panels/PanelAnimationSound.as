/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.worldmodel.animation.AnimationSound;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.plaf.spas.SpasUI;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.GUI.components.*;

public class PanelAnimationSound extends ExpandableBox
{
	private var _ani:Animation
	private var _sound:AnimationSound
	public function PanelAnimationSound( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {
		_ani = $ebco.rootObject
		_ani.sound = $ebco.item
		
		if ( null == $ebco.item )
			_ani.sound = $ebco.item = new AnimationSound()
		
		$ebco.itemBox.showReset = true
		super( $parent, $ebco );
	}
	
	override protected function collapasedInfo():String  {
		if ( AnimationSound.SOUND_INVALID == _ani.sound.soundFile ) {
			_ebco.itemBox.showNew = true
			return "No sound defined"
		}
		
		_ebco.itemBox.showNew = false
		_ebco.itemBox.showReset = true
		return _ani.sound.soundFile + " min: " + _ani.sound.soundRangeMin + " max: " + _ani.sound.soundRangeMax
	}
	
	override protected function resetElement():void  { 
		_ani.sound.reset()
		changeMode()
	}
	
	// This handles the new model transform
	override protected function newItemHandler( $me:UIMouseEvent ):void 		{ 
		
		_ani.sound.soundFile = "Undefined Sound"
		changeMode() // collapse container
		changeMode() // reexpand so that new item is at the bottom
	}
	
	override protected function expand():void {
		super.expand()
		
		if ( AnimationSound.SOUND_INVALID == _ani.sound.soundFile ) {
			return
		}
		
		_itemBox.addElement( new ComponentLabelInput( "Name"
									, function ($e:TextEvent):void { _ani.sound.soundFile = $e.target.text; setChanged(); }
									, _ani.sound.soundFile ? _ani.sound.soundFile : "No sound"
									, width - 20 ) )
		
		_itemBox.addElement( new ComponentLabelInput( "RangeMax"
									  , function ($e:TextEvent):void { _ani.sound.soundRangeMax = int( $e.target.text ); setChanged(); }
									  , _ani.sound.soundRangeMax ? String( _ani.sound.soundRangeMax ) : "No max range"
									  , width - 20 ) )
											
		_itemBox.addElement( new ComponentLabelInput( "RangeMin"
									  , function ($e:TextEvent):void { _ani.sound.soundRangeMin = int( $e.target.text ); setChanged(); }
									  , _ani.sound.soundRangeMin ? String( _ani.sound.soundRangeMin ) : "No min range"
									  , width - 20 ) )
	}
	
	/*
	private function deleteSound( $me:UIMouseEvent ):void {
		removeElements();
		_ani.sound = null;
		var newItem:Button = new Button( "Add Sound", width - 20, ITEM_HEIGHT );
		$evtColl.addEvent( newItem, UIMouseEvent.RELEASE, addSound );
		addElement( newItem );
		height = 40;
	}
	*/
	/*
	private function addSound( $me:UIMouseEvent ):void {
		removeElements();
		if ( null == _ani.sound )
			_ani.sound = new AnimationSound();
		layout.orientation = LayoutOrientation.VERTICAL;			
		
		var cli:ComponentLabelInput;
		cli = new ComponentLabelInput( "Name"
									  , function ($e:TextEvent):void { _ani.sound.soundFile = $e.target.text; setChanged(); }
									  , _ani.sound.soundFile ? _ani.sound.soundFile : "No sound"
									  , width - 20 )
											
		height += cli.height + padding;
		addElement( cli );
		
		cli = new ComponentLabelInput( "RangeMax"
									  , function ($e:TextEvent):void { _ani.sound.soundRangeMax = int( $e.target.text ); setChanged(); }
									  , _ani.sound.soundRangeMax ? String( _ani.sound.soundRangeMax ) : "No max range"
									  , width - 20 )
											
		height += cli.height + padding;
		addElement( cli );
		
		cli = new ComponentLabelInput( "RangeMin"
									  , function ($e:TextEvent):void { _ani.sound.soundRangeMin = int( $e.target.text ); setChanged(); }
									  , _ani.sound.soundRangeMin ? String( _ani.sound.soundRangeMin ) : "No min range"
									  , width - 20 )
											
		height += cli.height + padding + 10;
		addElement( cli );
		
		var deleteButton:Button = new Button( "Remove Sound", width - 20, ITEM_HEIGHT );
		deleteButton.padding = 0;
		$evtColl.addEvent( deleteButton, UIMouseEvent.RELEASE, deleteSound );
		addElement( deleteButton );
	}
	*/
	private function setChanged():void {
		_ani.changed = true;
	}
	
}
}