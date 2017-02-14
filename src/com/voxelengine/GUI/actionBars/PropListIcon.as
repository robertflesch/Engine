/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
import com.voxelengine.renderer.Renderer;

import flash.events.Event;

import org.flashapi.swing.Box;
import org.flashapi.swing.Image
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.layout.AbsoluteLayout
import org.flashapi.swing.text.UITextField;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.VVCanvas;
import com.voxelengine.GUI.voxelModels.WindowRegionModels;

public class PropListIcon extends VVCanvas
{
	protected var _outline:Image
	private const IMAGE_SIZE:int = 128
	private var _butCurrent:Box
	private var _parentWidth:int
	
	public function PropListIcon( $width:int ) {
		_parentWidth = $width
		super( 128, 128 )
		// These numbers come from the size of the artwork, and from the size of the toolbar below it.
		layout = new AbsoluteLayout()
		_outline = new Image( Globals.texturePath + "list.png" )
		eventCollector.addEvent( _outline, UIMouseEvent.PRESS, pressShape )
		addElement( _outline )
		var it:UITextField = new UITextField()
		it.text = "Prop List (N)"
		it.x = 24
		it.y = 48
		it.textColor = 0xFFFFFF
		addElement( it )
		display()
		resizeObject( null )
		visible = false
		Globals.g_app.stage.addEventListener( Event.RESIZE, resizeObject );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}
	
	protected function onRemoved( event:UIOEvent ):void {
		Globals.g_app.stage.removeEventListener( Event.RESIZE, resizeObject );
	}
	
	private function pressShape( $e:UIMouseEvent ):void {
		new WindowRegionModels()
	}
	
	
	public function resizeObject(event:Event):void {
		var halfRW:int = Renderer.renderer.width / 2

		y = Renderer.renderer.height - height - 24
		x = halfRW - (width / 2) + _parentWidth/2 + 28
	}
	
	public function show():void { _outline.visible = true; visible = false }
	public function hide():void { _outline.visible = false; visible = false }
}
}