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
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;	
	import com.voxelengine.events.AppEvent;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	public class WindowReleaseMenu extends VVCanvas
	{
		static private var _s_currentInstance:WindowReleaseMenu = null;
		static public function get currentInstance():WindowReleaseMenu { return _s_currentInstance; }
		private var _fpsLabel:Label = new Label("FPS:");
		public function fps():String { return _fpsLabel.text; }
		private var _locLabel:Label = new Label("x: 0  y: 0  z: 0");
		private var _rotLabel:Label = new Label("x: 0  y: 0  z: 0");

		private var _startTime:int = 0;
		protected var _frames:int = 0;
		protected var _fps:int = 0;
		protected var _prefix:String = "";
		
		public function WindowReleaseMenu():void 
		{ 
			super();
			_s_currentInstance = this;
			autoSize = false;
			padding = 10;
			shadow = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			layout.horizontalAlignment = LayoutHorizontalAlignment.RIGHT;
			
			var name:Label = new Label( "VoxelVerse 2015.12.05 - 5:36 PM" );
			name.fontSize = 14;
			name.fontColor = 0xffffff;
			addElement( name );
			
			var ss:Label = new Label( "Screen Shot F12" );
			ss.fontSize = 14;
			ss.fontColor = 0x0000ff;
			addElement( ss );
			
			var fs:Label = new Label( "FullScreen F9" );
			fs.fontSize = 14;
			fs.fontColor = 0x0000ff;
			addElement( fs );
			
			_startTime = getTimer();
			_prefix = "FPS: ";
			_fpsLabel.fontSize = 14;
			_fpsLabel.fontColor = 0xff0000;
			addElement( _fpsLabel );
			
			_locLabel.fontSize = 14;
			_locLabel.fontColor = 0x808080;
			addElement( _locLabel );
			
			_rotLabel.fontSize = 14;
			_rotLabel.fontColor = 0x808080;
			addElement( _rotLabel );
			
			var spacer:Label = new Label( "" );
			spacer.fontSize = 14;
			addElement( spacer );
			
			display( 0, 0 );	
			
			AppEvent.addListener( Event.ENTER_FRAME, onEnterFrame )
			Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
			
			onResize(null);
		} 
		
        protected function onResize(event:Event):void
        {
			move( Renderer.renderer.width - 120, 0 );
		}
		
		private function fullScreenHandler(e:UIMouseEvent):void 
		{
			VoxelVerseGUI.currentInstance.toggleFullscreen();
		}
		
		private function sandboxHandler(e:UIMouseEvent):void 
		{
			if ( !WindowSandboxList.isActive )
				WindowSandboxList.create();
		}
		
		private function screenShotHandler(e:UIMouseEvent):void 
		{
			Renderer.renderer.screenShot( true );
		}
		
		private function onEnterFrame( event:Event ):void
		{
			updateFPS();
			updateLocation();
		}
		
		private function updateLocation():void
		{
			if ( VoxelModel.controlledModel )
			{
				var loc:Vector3D = VoxelModel.controlledModel.instanceInfo.positionGet;
				_locLabel.text = "Loc x: " + int( loc.x ) + "  y: " + int( loc.y ) + "  z: " + int( loc.z ); 
				var rot:Vector3D = VoxelModel.controlledModel.instanceInfo.rotationGet;
				_rotLabel.text = "Rot x: " + int( rot.x ) + "  y: " + int( rot.y ) + "  z: " + int( rot.z ); 
			}
		}
		
		private function updateFPS():void
		{
			_frames++;
			var time:int = getTimer();
			var elapsed:int = time - _startTime;
			if(elapsed >= 1000)
			{
				//_fps = Math.round(_frames * 1000 / elapsed);
				_fps = 1000/VoxelVerse.frameTime();
				_frames = 0;
				_startTime = time;
				// update the parent component with the right 
				_fpsLabel.text = _prefix + _fps.toString();
			}
			
		}
		
		public static function addCommasToLargeInt( value:int ):String 
		{
			var answer:String = "";
			var sub:String = "";
			var remainder:String = value.toString();
			var len:int = remainder.length;
			for (; 3 < len;) {
				sub = "," + remainder.substr( len - 3, len );
				remainder = remainder.substr( 0, len - 3 );
				len = remainder.length;
				answer = sub + answer;
			}
			
			return answer;
		}
		
	}
}