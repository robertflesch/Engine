/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.GUIEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.renderer.Renderer;

public class WindowBeastControlQuery extends VVCanvas
{
	static private var _s_currentInstance:WindowBeastControlQuery = null;
	static public function get currentInstance():WindowBeastControlQuery { return _s_currentInstance; }

	private var _beastInstanceGuid:String = "";
	private const TOOL_BAR_HEIGHT:int = 140;
	private var window_offset:int = TOOL_BAR_HEIGHT;


	static public function handleModelEvents( $me:ModelEvent ):void {
		if ( ModelEvent.TAKE_CONTROL == $me.type ) {
			if ( WindowBeastControlQuery.currentInstance )
				WindowBeastControlQuery.currentInstance.remove();
		}
	}

	public function WindowBeastControlQuery( $beastInstanceGuid:String ):void {
		super();
		if ( null != WindowBeastControlQuery.currentInstance )
			Log.out( "WindowBeastControlQuery.constructor - trying to create window when one already exists" );

		_beastInstanceGuid = $beastInstanceGuid;
		_s_currentInstance = this;
		autoSize = true;

		var button:Button = new Button( "F key to take control" );
		button.width = 300;
		button.height = 80;
		button.addEventListener(MouseEvent.CLICK, takeControlMouse );
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, takeControlKey );
		addElement( button );

		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize );
		RegionEvent.addListener( RegionEvent.LOAD, onRegionLoad );
		GUIEvent.addListener( GUIEvent.TOOLBAR_HIDE, guiEventHandler );
		GUIEvent.addListener( GUIEvent.TOOLBAR_SHOW, guiEventHandler );
		ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved );
		addEventListener(UIOEvent.REMOVED, onRemoved );

		display();
		onResize( null );
	}

	private function modelRemoved( $me:ModelEvent):void {
		if ( $me.instanceGuid == _beastInstanceGuid )
			remove();
	}

	protected function onResize( event:Event ):void {
		move( Renderer.renderer.width / 2 - width / 2, Renderer.renderer.height - height - window_offset );
	}

	private function onRegionLoad ( le:RegionEvent ):void {
		remove();
	}


	// Window events
	private function onRemoved( event:UIOEvent ):void {
		removeEventListener(UIOEvent.REMOVED, onRemoved );
		Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize );
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, takeControlKey );
		RegionEvent.removeListener( RegionEvent.LOAD, onRegionLoad );
		GUIEvent.removeListener( GUIEvent.TOOLBAR_HIDE, guiEventHandler );
		GUIEvent.removeListener( GUIEvent.TOOLBAR_SHOW, guiEventHandler );
		ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED, modelRemoved );
		_s_currentInstance = null;
	}

	private function takeControl():void {
		var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _beastInstanceGuid );
		if ( vm )
		{
			remove();
			vm.takeControl( VoxelModel.controlledModel );
		}
	}

	private function takeControlKey(e:KeyboardEvent):void {
		if ( Keyboard.F == e.keyCode )
			takeControl();
	}

	private function takeControlMouse(event:UIMouseEvent):void {
		event.target.removeEventListener(MouseEvent.CLICK, takeControl );
		takeControl();
	}

	private function guiEventHandler( e:GUIEvent ):void	{
		if ( GUIEvent.TOOLBAR_HIDE == e.type )
			window_offset = 0;
		else if ( GUIEvent.TOOLBAR_SHOW == e.type )
			window_offset = TOOL_BAR_HEIGHT;

		onResize( null );
	}
}
}