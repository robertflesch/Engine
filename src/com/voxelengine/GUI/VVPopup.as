/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.renderer.Renderer;

import flash.events.Event;

import org.flashapi.swing.Popup;
import org.flashapi.swing.effect.*;
import org.flashapi.swing.event.UIOEvent;

import com.voxelengine.Globals;

public class VVPopup extends Popup
{
	
	public function VVPopup( title:String, width:Number = 150, height:Number = 80 )
	{
		super( title, width, height );
		
//		hasDisplayEffect = true;
//		displayEffectRef = ScaleIn;
//		displayEffectDuration = 500;
		
		Globals.openWindowCount = Globals.openWindowCount + 1;
		Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}

	protected function onResize($event:Event):void
	{
		move( Renderer.renderer.width / 2 - (width + 10) / 2, Renderer.renderer.height / 2 - (height + 10) / 2 );
	}
	
	override public function remove():void {
		super.remove();
//		hasRemoveEffect = true;
//		removeEffectRef = SlideOut;
//		removeEffectDuration = 500;
		Globals.g_app.stage.removeEventListener( Event.RESIZE, onResize );
	}
	
	protected function onRemoved( event:UIOEvent ):void
	{
		Globals.openWindowCount = Globals.openWindowCount - 1;
		eventCollector.removeAllEvents();
	}
	
}
}