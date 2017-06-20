/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.models
{
import com.voxelengine.GUI.VVAlert;
import com.voxelengine.events.CursorShapeEvent;
import com.voxelengine.GUI.VVCanvas;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.events.KeyboardEvent;
import flash.events.Event;
import flash.ui.Keyboard;

import org.flashapi.swing.Alert;

import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.Image;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;

public class ModelPlacementType extends VVCanvas {
	protected var _outline:Image;
	private var _butCurrent:Box;
	static public var placementType:String;
	static public const PLACEMENT_TYPE_PARENT:String = "PLACEMENT_TYPE_PARENT";
	static public const PLACEMENT_TYPE_CHILD:String = "PLACEMENT_TYPE_CHILD";

	public function ModelPlacementType() {
		super( 84, 74 );
		layout = new AbsoluteLayout();
		_outline = new Image( Globals.texturePath + "toolSelector.png" );
		addElement( _outline );
		display();
		addModelPlacementType();
		resizeObject( null );
	}
	
	public function resizeObject(event:Event):void {
		var halfRW:int = Renderer.renderer.width / 3;

		y = Renderer.renderer.height - (height + 84);
		x = halfRW - (width / 2);
	}
	
	public function addModelPlacementType():void {
		const IMAGE:int = 64;
		_butCurrent = new Box(IMAGE, IMAGE);
		_butCurrent.x = 10;
		_butCurrent.y = 10;
		_butCurrent.data = "auto";
		_butCurrent.backgroundTexture = "assets/textures/parent.jpg";
		addElement( _butCurrent );
		placementType = PLACEMENT_TYPE_PARENT;

		var hk:Label = new Label("", 20);
		hk.x = 33;
		hk.y = -4;
		hk.fontColor = 0xffffff;
		hk.text = "F8";
		addElement(hk);
		
		eventCollector.addEvent( _butCurrent, UIMouseEvent.PRESS, pressShape );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressShape );
	}
	
	public function pressShapeHotKey(e:KeyboardEvent):void { nextShape(); }
	private function pressShape(event:UIMouseEvent):void { nextShape(); }
	
	private function nextShape():void {
//		if ( "child" == _butCurrent.data) {
//			_butCurrent.data = "auto";
//			_butCurrent.backgroundTexture = "assets/textures/auto.jpg";
//			placementType = PLACEMENT_TYPE_INDEPENDENT;
//		}
		if ( "parent" == _butCurrent.data) {
			_butCurrent.data = "child";	
			_butCurrent.backgroundTexture = "assets/textures/child.jpg";
			placementType = PLACEMENT_TYPE_CHILD;
			var cursorModel:VoxelModel = EditCursor.currentInstance.objectModel;
			if ( cursorModel && cursorModel.modelInfo.oxelPersistence && cursorModel.modelInfo.oxelPersistence.oxelCount ) {
				var selectedModel:VoxelModel = VoxelModel.selectedModel;
				if ( selectedModel && selectedModel.modelInfo.oxelPersistence && selectedModel.modelInfo.oxelPersistence.oxelCount ){
					if ( cursorModel.modelInfo.oxelPersistence.oxel.gc.bound >= selectedModel.modelInfo.oxelPersistence.oxel.gc.bound ){
						nextShape();
						(new VVAlert( "The cursor model has to be smaller than the selected model ", 450 )).display();
					}
				}
			}
		}
		else { //  if ( "child" == _butCurrent.data) {
			_butCurrent.data = "parent";
			_butCurrent.backgroundTexture = "assets/textures/parent.jpg";
			placementType = PLACEMENT_TYPE_PARENT;
		}

		show();
	}
	
	public function show():void {
		// only add listener when going from invisible to visible
		if ( false == visible )
			VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
			
		visible = true;
		_outline.visible = true;
		
		CursorShapeEvent.dispatch( new CursorShapeEvent( CursorShapeEvent.MODEL_AUTO ) );
	}
	
	public function hide():void {
		// only remove listener when going from visible to invisible
		if ( true == visible )
			VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, hotKeyInventory );
		visible = false;
		_outline.visible = false;
	}

	public function hotKeyInventory(e:KeyboardEvent):void {
		if  ( !Globals.active )
			return;

		if ( Keyboard.F8 == e.keyCode )
			pressShapeHotKey(e);
	}

}
}