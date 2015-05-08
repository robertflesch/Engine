
package com.voxelengine.worldmodel.models
{
import com.voxelengine.GUI.VVCanvas;
import com.voxelengine.worldmodel.models.types.VoxelModel;
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
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.TypeInfo;

public class ModelPlacementType extends VVCanvas
{
	protected var _outline:Image;
	private const IMAGE_SIZE:int = 64;
	private var _butCurrent:Box;
	static private var _s_placementType:String;
	
	static public const PLACEMENT_TYPE_PARENT:String = "PLACEMENT_TYPE_PARENT";
	static public const PLACEMENT_TYPE_CHILD:String = "PLACEMENT_TYPE_CHILD";
	
	static public function modelPlacementTypeGet():String { return _s_placementType;  }
	
	public function ModelPlacementType()
	{
		super( 84, 74 );
		_s_placementType = PLACEMENT_TYPE_CHILD;
		layout = new AbsoluteLayout();
		_outline = new Image( Globals.appPath + "assets/textures/toolSelector.png" );
		addElement( _outline );
		display();
		show();
		addModelPlacementType();
		resizeObject( null );
	}
	
	public function resizeObject(event:Event):void 
	{
		var halfRW:int = Globals.g_renderer.width / 3;

		y = Globals.g_renderer.height - (height + 84);
		x = halfRW - (width / 2);
	}
	
	public function addModelPlacementType():void
	{
		_butCurrent = new Box(IMAGE_SIZE, IMAGE_SIZE);
		_butCurrent.x = 10;
		_butCurrent.y = 10;
		_butCurrent.data = "child";
		_butCurrent.backgroundTexture = "assets/textures/child.jpg";
		addElement( _butCurrent );
		
		
		var hk:Label = new Label("", 20);
		hk.x = 33;
		hk.y = -4;
		hk.fontColor = 0xffffff;
		hk.text = "F8";
		addElement(hk);
		
		eventCollector.addEvent( _butCurrent, UIMouseEvent.PRESS, pressShape );
		//eventCollector.addEvent( _butCurrent, UIMouseEvent.RELEASE, releaseShape );
		eventCollector.addEvent( hk, UIMouseEvent.PRESS, pressShape );
		//eventCollector.addEvent( hk, UIMouseEvent.RELEASE, pressShape );
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
		if ( "child" == _butCurrent.data) {
			_butCurrent.data = "parent";	
			_butCurrent.backgroundTexture = "assets/textures/parent.jpg";
			_s_placementType = PLACEMENT_TYPE_PARENT;
			VoxelModel.selectedModel = EditCursor.currentInstance.objectModelGet();
		} 
		else if ( "parent" == _butCurrent.data) {
			_butCurrent.data = "child";	
			_butCurrent.backgroundTexture = "assets/textures/child.jpg";
			_s_placementType = PLACEMENT_TYPE_CHILD;
			VoxelModel.selectedModel = null;
		} 
	}
	
	public function show():void
	{
		_outline.visible = true;
		if ( false == visible )
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		visible = true;
	}
	
	public function hide():void
	{
		_outline.visible = false;
		if ( true == visible )
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, hotKeyInventory );
		visible = false;
	}
	
}
}