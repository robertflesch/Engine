/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI
{
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import flash.events.Event;
	import flash.utils.Timer;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import flash.geom.Vector3D;
	import flash.events.Event;
	import flash.events.TimerEvent;
	
	public class CanvasHeading extends VVCanvas
	{
		static private var _s_currentInstance:CanvasHeading = null;
		private var fudgeFactor:int = 20;
		private var _heading:Slider = null;
		private var _loc:Text = null;
		private var _vel:Text = null;
		private var _repeatTimer:Timer = null;
		static public function get currentInstance():CanvasHeading { return _s_currentInstance; }

		public function CanvasHeading($instanceGuid:String ):void {
			super();
			_s_currentInstance = this;
			var _instanceGuid:String=$instanceGuid;
			//alpha = 0.5;
			layout.orientation = LayoutOrientation.VERTICAL;

			_heading = new Slider( 400, "horizontal" );
			/*
			 var laf:Object = _heading.getLaf();
			 var lafRef:Class = _heading.getLafRef();
			 var test:SpasLabelUI = _heading.lookAndFeel.getLabelLaf() as SpasLabelUI;
			 //var test2:SpasLabelUI = new SpasLabelUI( test.dto );
			 var tformat:UITextFormat = test.getTextFormat();
			 tformat.color = 0xFF0000;
			 //_heading.lookAndFeel.setLabelLaf( test2 );
			 */
			_heading.liveDragging = false;
			_heading.labels = ["S", "W", "N", "E", "S"];
			_heading.value = 50;
			addElement( _heading );

			_loc = new Text( 400, 30 );
			_loc.text = "";
			_loc.textAlign = TextAlign.CENTER;
			_loc.textFormat.color = 0xFFFFFF;
			addElement( _loc );

			_vel = new Text( 400, 30 );
			_vel.text = "";
			_vel.textAlign = TextAlign.CENTER;
			_vel.textFormat.color = 0xFFFFFF;
			addElement( _vel );

			display( Renderer.renderer.width / 2 - (_heading.trackLength + fudgeFactor) / 2, 0 );

			Globals.g_app.stage.addEventListener(Event.RESIZE, onResizeHeading );
			addEventListener(UIOEvent.REMOVED, onRemoved );

			_repeatTimer = new Timer( 250, 0 );
			_repeatTimer.addEventListener(TimerEvent.TIMER, onRepeat);
			_repeatTimer.start();
		}

		protected function onRepeat(event:TimerEvent):void
		{
			if ( VoxelModel.controlledModel.instanceInfo.controllingModel )
			{
				var loc:Vector3D = VoxelModel.controlledModel.instanceInfo.controllingModel.instanceInfo.positionGet;
				_loc.text = "x: " + int( loc.x ) + "  y: " + int( loc.y ) + "  z: " + int( loc.z ); 
				var vel:Vector3D = VoxelModel.controlledModel.instanceInfo.controllingModel.instanceInfo.velocityGet;
				_vel.text = "x: " + int( vel.x ) + "  y: " + int( vel.y ) + "  z: " + int( vel.z ); 
				
				var rot:Number = -VoxelModel.controlledModel.instanceInfo.controllingModel.instanceInfo.rotationGet.y % 360;
				var calRot:Number = 0;
				if ( 180 < rot )
					calRot = 50 - ( ( rot - 180 ) * 100 / 360 );
				else if ( -180 > rot )	
					calRot = Math.abs( ( rot + 180 ) / 360 ) * 100;
				else	
					calRot = 50 - ( rot * 100 / 360 );
					
				_heading.value = calRot;
				//Log.out( "WindowHeading.onRepeat: " + calRot );
			}
		}

		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResizeHeading );
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			_repeatTimer.stop();
			_s_currentInstance = null;
		}
		
        protected function onResizeHeading( event:Event ):void
        {
			move( Renderer.renderer.width / 2 - (_heading.trackLength + fudgeFactor) / 2, 0 );
		}
		
	}
}