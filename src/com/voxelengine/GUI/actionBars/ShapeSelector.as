
package com.voxelengine.GUI.actionBars
{
import com.voxelengine.renderer.Renderer;

import flash.events.KeyboardEvent
import flash.events.MouseEvent
import flash.events.Event
import org.flashapi.swing.cursor.Cursor

import org.flashapi.swing.Box
import org.flashapi.swing.Label
import org.flashapi.swing.Image
import org.flashapi.swing.constants.BorderStyle
import org.flashapi.swing.event.UIMouseEvent
import org.flashapi.swing.layout.AbsoluteLayout

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.CursorShapeEvent
import com.voxelengine.GUI.VVCanvas
import com.voxelengine.worldmodel.models.types.EditCursor
import com.voxelengine.worldmodel.TypeInfo

public class ShapeSelector extends VVCanvas
{
	protected var _outline:Image
	private const IMAGE_SIZE:int = 64
	private var _butCurrent:Box
	
	public function ShapeSelector() {
		super( 84, 74 )
		layout = new AbsoluteLayout()
		_outline = new Image( Globals.texturePath + "toolSelector.png" )
		addElement( _outline )
		display()
		addShapeSelector()
		resizeObject( null )
		visible = false
	}
	
	public function resizeObject(event:Event):void {
		var halfRW:int = Renderer.renderer.width / 2

		y = Renderer.renderer.height - (height + 84)
		x = halfRW - (width / 2) - 240
	}
	
	public function addShapeSelector():void
	{
		_butCurrent = new Box(IMAGE_SIZE, IMAGE_SIZE)
		_butCurrent.x = 10
		_butCurrent.y = 10
		_butCurrent.data = "square"
		_butCurrent.backgroundTexture = "assets/textures/square.jpg"
		addElement( _butCurrent )
		
		
		var hk:Label = new Label("", 20)
		hk.x = 33
		hk.y = -4
		hk.fontColor = 0xffffff
		hk.text = "F8"
		addElement(hk)
		
		eventCollector.addEvent( _butCurrent, UIMouseEvent.PRESS, pressShape )
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressShape )
	}
	
	public function hotKeyInventory(e:KeyboardEvent):void 
	{
		if  ( !Globals.active )
			return
			
		if ( 119 == e.keyCode )
			pressShapeHotKey(e)
	}
	
	public function pressShapeHotKey(e:KeyboardEvent):void  { nextShape() }
	private function pressShape(event:UIMouseEvent):void  { nextShape() }
	
	private function nextShape():void
	{
		if ( "square" == _butCurrent.data)
		{
			_butCurrent.data = "cylinder"	
			_butCurrent.backgroundTexture = "assets/textures/cylinder.jpg"
		} 
		else if ( "cylinder" == _butCurrent.data)
		{
			_butCurrent.data = "sphere"	
			_butCurrent.backgroundTexture = "assets/textures/sphere.jpg"
		} 
		else if ( "sphere" == _butCurrent.data)
		{
			_butCurrent.data = "square"	
			_butCurrent.backgroundTexture = "assets/textures/square.jpg"
		}
		show()
	}
	
	public function show():void
	{
		_outline.visible = true
		if ( false == visible )
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory )
		visible = true
		Globals.g_app.stage.addEventListener( Event.RESIZE, resizeObject )
		if ( "square" == _butCurrent.data)
			CursorShapeEvent.dispatch( new CursorShapeEvent( CursorShapeEvent.SQUARE ) )
		else if ( "cylinder" == _butCurrent.data)
			CursorShapeEvent.dispatch( new CursorShapeEvent( CursorShapeEvent.CYLINDER ) )
		else if ( "sphere" == _butCurrent.data)
			CursorShapeEvent.dispatch( new CursorShapeEvent( CursorShapeEvent.SPHERE ) )
		resizeObject( null )
	}
	
	public function hide():void
	{
		_outline.visible = false
		if ( true == visible )
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory )
		visible = false
		Globals.g_app.stage.removeEventListener( Event.RESIZE, resizeObject )
	}
}
}