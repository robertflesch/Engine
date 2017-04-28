/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.animation.AnimationSound;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.plaf.spas.VVUI;
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
		_ani.animationSound = $ebco.item
		

		$ebco.itemBox.showReset = true
		super( $parent, $ebco );
//		if ( null == $ebco.item ) {
//			throw new Error( "REFACTOR");
//			_ani.animationSound = $ebco.item = new AnimationSound( _ani, AnimationSound.DEFAULT_OBJECT )
//		}
	}
	
	override protected function collapasedInfo():String  {
		//_ebco.itemBox.showNew = false;
		_ebco.itemBox.showReset = true;
		if ( _ani && _ani.animationSound )
			return " min: " + _ani.animationSound.soundRangeMin + " max: " + _ani.animationSound.soundRangeMax + "  " + _ani.animationSound.guid
		else
			return "New Animation Transform";
	}
	
	override protected function resetElement():void  { 
		_ani.animationSound.reset();
		changeMode()
	}
	
	// This handles the new model transform
	override protected function newItemHandler( $me:UIMouseEvent ):void 		{
		_ani.animationSound = new AnimationSound( Globals.getUID(), null, null );
		//_ani.animationSound.guid = "Undefined Sound";
		changeMode(); // collapse container
		changeMode(); // reexpand so that new item is at the bottom
	}
	
	override protected function expand():void {
		super.expand();

		if ( _ani.animationSound ) {
			_itemBox.addElement(new ComponentLabelInput("Name"
					, function ($e:TextEvent):void {
						_ani.animationSound.guid = $e.target.text;
						setChanged();
					}
					, _ani.animationSound.guid
					, width - 20))

			_itemBox.addElement(new ComponentLabelInput("RangeMax"
					, function ($e:TextEvent):void {
						_ani.animationSound.soundRangeMax = int($e.target.text);
						setChanged();
					}
					, String(_ani.animationSound.soundRangeMax)
					, width - 20))

			_itemBox.addElement(new ComponentLabelInput("RangeMin"
					, function ($e:TextEvent):void {
						_ani.animationSound.soundRangeMin = int($e.target.text);
						setChanged();
					}
					, String(_ani.animationSound.soundRangeMin)
					, width - 20))
		}
	}
	
	/*
	private function deleteSound( $me:UIMouseEvent ):void {
		removeElements();
		_ani.animationSound = null;
		var newItem:Button = new Button( "Add Sound", width - 20, ITEM_HEIGHT );
		$evtColl.addEvent( newItem, UIMouseEvent.RELEASE, addSound );
		addElement( newItem );
		height = 40;
	}
	*/
	/*
	private function addSound( $me:UIMouseEvent ):void {
		removeElements();
		if ( null == _ani.animationSound )
			_ani.animationSound = new AnimationSound();
		layout.orientation = LayoutOrientation.VERTICAL;			
		
		var cli:ComponentLabelInput;
		cli = new ComponentLabelInput( "Name"
									  , function ($e:TextEvent):void { _ani.animationSound.guid = $e.target.text; setChanged(); }
									  , _ani.animationSound.guid ? _ani.animationSound.guid : "No animationSound"
									  , width - 20 )
											
		height += cli.height + padding;
		addElement( cli );
		
		cli = new ComponentLabelInput( "RangeMax"
									  , function ($e:TextEvent):void { _ani.animationSound.soundRangeMax = int( $e.target.text ); setChanged(); }
									  , _ani.animationSound.soundRangeMax ? String( _ani.animationSound.soundRangeMax ) : "No max range"
									  , width - 20 )
											
		height += cli.height + padding;
		addElement( cli );
		
		cli = new ComponentLabelInput( "RangeMin"
									  , function ($e:TextEvent):void { _ani.animationSound.soundRangeMin = int( $e.target.text ); setChanged(); }
									  , _ani.animationSound.soundRangeMin ? String( _ani.animationSound.soundRangeMin ) : "No min range"
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