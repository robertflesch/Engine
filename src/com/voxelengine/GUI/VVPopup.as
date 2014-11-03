
package com.voxelengine.GUI
{
import flash.events.Event;

import org.flashapi.swing.Popup;
import org.flashapi.swing.effect.*;
import org.flashapi.swing.event.UIOEvent;

import com.voxelengine.Globals;

public class VVPopup extends Popup
{
	
	public function VVPopup( title:String )
	{
		super( title );
		hasDisplayEffect = true;
		displayEffectRef = ScaleIn;
		displayEffectDuration = 500;
		
		Globals.openWindowCount = Globals.openWindowCount + 1;
		eventCollector.addEvent( this, Event.RESIZE, onResize );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}

	protected function onResize($event:Event):void
	{
		move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
	}
	
	override public function remove():void {
		hasRemoveEffect = true;
		removeEffectRef = SlideOut;
		removeEffectDuration = 500;
		super.remove();
	}
	
	protected function onRemoved( event:UIOEvent ):void
	{
		Globals.openWindowCount = Globals.openWindowCount - 1;
		eventCollector.removeAllEvents();
	}
	
}
}