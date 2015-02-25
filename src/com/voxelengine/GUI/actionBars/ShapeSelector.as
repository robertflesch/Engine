
package com.voxelengine.GUI.actionBars
{
import com.voxelengine.GUI.VVCanvas;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.Event;

import org.flashapi.swing.Box;
import org.flashapi.swing.Label;
import org.flashapi.swing.Image;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.EditCursor;
import com.voxelengine.worldmodel.TypeInfo;

public class ShapeSelector extends VVCanvas
{
	protected var _outline:Image;
	private const IMAGE_SIZE:int = 64;
	private var _butCurrent:Box;
	
	public function ShapeSelector()
	{
		super( 84, 74 );
		layout = new AbsoluteLayout();
		_outline = new Image( Globals.appPath + "assets/textures/toolSelector.png" );
		addElement( _outline );
		display();
		show();
		addShapeSelector();
		resizeObject( null );
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
	}
	
	public function resizeObject(event:Event):void 
	{
		var halfRW:int = Globals.g_renderer.width / 3;

		y = Globals.g_renderer.height - (height + 84);
		x = halfRW - (width / 2);
	}
	
	public function addShapeSelector():void
	{
		_butCurrent = new Box(IMAGE_SIZE, IMAGE_SIZE);
		_butCurrent.x = 10;
		_butCurrent.y = 10;
		_butCurrent.data = "square";
		_butCurrent.backgroundTexture = "assets/textures/square.jpg";
		addElement( _butCurrent );
		
		
		var hk:Label = new Label("", 20);
		hk.x = 33;
		hk.y = -4;
		hk.fontColor = 0xffffff;
		hk.text = "F8";
		addElement(hk);
		
		eventCollector.addEvent( _butCurrent, UIMouseEvent.PRESS, pressShape );
		eventCollector.addEvent( _butCurrent, UIMouseEvent.RELEASE, releaseShape );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressShape );
		eventCollector.addEvent( hk, UIMouseEvent.RELEASE, pressShape );
	}
	
	public function hotKeyInventory(e:KeyboardEvent):void 
	{
		if  ( !Globals.active )
			return;
			
		if ( 119 == e.keyCode )
		{
			pressShapeHotKey(e);
		}
	}
	
	public function pressShapeHotKey(e:KeyboardEvent):void 
	{
		nextShape();
	}
	private function pressShape(event:UIMouseEvent):void 
	{
		nextShape();
	}
	private function nextShape():void
	{
		if ( "square" == _butCurrent.data)
		{
			_butCurrent.data = "cylinder";	
			_butCurrent.backgroundTexture = "assets/textures/cylinder.jpg";
			EditCursor.cursorType = EditCursor.CURSOR_TYPE_CYLINDER;
			if ( EditCursor.CURSOR_OP_DELETE == EditCursor.cursorOperation )
				EditCursor.cursorColor = TypeInfo.EDITCURSOR_CYLINDER;
			//EditCursor.cursorColor = TypeInfo.EDITCURSOR_CYLINDER_ANIMATED;
		} 
		else if ( "cylinder" == _butCurrent.data)
		{
			_butCurrent.data = "sphere";	
			_butCurrent.backgroundTexture = "assets/textures/sphere.jpg";
			EditCursor.cursorType = EditCursor.CURSOR_TYPE_SPHERE;
			if ( EditCursor.CURSOR_OP_DELETE == EditCursor.cursorOperation )
				EditCursor.cursorColor = TypeInfo.EDITCURSOR_ROUND;
		} 
		else if ( "sphere" == _butCurrent.data)
		{
			_butCurrent.data = "square";	
			_butCurrent.backgroundTexture = "assets/textures/square.jpg";
			EditCursor.cursorType = EditCursor.CURSOR_TYPE_GRAIN;
			if ( EditCursor.CURSOR_OP_DELETE == EditCursor.cursorOperation )
				EditCursor.cursorColor = TypeInfo.EDITCURSOR_SQUARE;
		}
	}
	
	private function releaseShape(e:UIMouseEvent):void 
	{
	}			
	
	public function show():void
	{
		_outline.visible = true;
		visible = true;
//		addListeners();
	}
	
	public function hide():void
	{
		_outline.visible = false;
		visible = false;
//		removeListeners();
	}
	
}
}