/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
import com.voxelengine.GUI.VVCanvas;
import com.voxelengine.renderer.Renderer;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;

import org.flashapi.swing.Image;
import org.flashapi.swing.Canvas;
import org.flashapi.swing.Box;
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.UIOEvent;

import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.inventory.ObjectInfo;

public class QuickInventory extends VVCanvas
{
	private static var s_currentItemSelection:int = -1;
	public static function get currentItemSelection():int { return s_currentItemSelection }
	public static function set currentItemSelection(val:int):void { s_currentItemSelection = val; }
	
	protected var _outline:Image;
	protected var _imageSize:int;
	protected var _selector:Sprite;
	protected var _selectorXOffset:int;
	protected var _offsetFromBottom:int;
	protected var _boxes:Vector.<BoxInventory> = new Vector.<BoxInventory>(10,true);
	public function get boxes():Vector.<BoxInventory> { return _boxes;}
	
	public function QuickInventory($width:int, $height:int, $imageSize:int, $outlineName:String, $offsetFromBottom:int = 0 ) {
		super( $width, $height );
		layout = new AbsoluteLayout();
		
		_imageSize = $imageSize;
		_offsetFromBottom = $offsetFromBottom;
		
		_outline = new Image( Globals.texturePath + $outlineName );
		_outline.cacheAsBitmap = true;
		addElement( _outline );
		
		Globals.g_app.stage.addEventListener( Event.RESIZE, resizeObject );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
	}
	
	protected function onRemoved( event:UIOEvent ):void {
		Globals.g_app.stage.removeEventListener( Event.RESIZE, resizeObject );
	}
	
	public function addTypeAt( ti:TypeInfo, slot:int ):void {
		var box:Box = _boxes[ slot ];
		box.backgroundTexture = ti.image;
		box.data = ti;
	}
	
	public function getIndexFromBox( box:Box ):int {
		var index:int = box.x / _imageSize;
		return index;
	}
	
	public function addSelector():void {
//		_selector = new Canvas(_imageSize, _imageSize);
		_selector = new Sprite();
		_selector.y = height - _imageSize;
		_selector.x = _selectorXOffset
		_selector.filters = [new GlowFilter(0xff0000, .5)];
		with (_selector.graphics) {
			lineStyle(2, 0xff0000, .5);
			drawRect(2, 2, _imageSize - 3, _imageSize - 3);
			endFill();
		}
		addElement(_selector);
	}
	
	public function moveSelector( $box:UIObject ):void {
		_selector.x = $box.x;
		_selector.y = height - _imageSize;
		currentItemSelection = ( x - _selectorXOffset) / _imageSize;
	}
	
	protected function buildItems():void { }
	
	public function resizeObject(event:Event):void {
		var halfRW:int = Renderer.renderer.width / 2;
		var halfRH:int = Renderer.renderer.height / 2;

		y = Renderer.renderer.height - (height + _offsetFromBottom);
		x = halfRW - (width / 2);
	}

}
}