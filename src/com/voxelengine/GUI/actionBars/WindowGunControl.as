/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/


package com.voxelengine.GUI.actionBars
{
	import com.voxelengine.GUI.VVCanvas;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.WeaponEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.weapons.Gun;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import com.voxelengine.worldmodel.Region;
	
	public class WindowGunControl extends VVCanvas
	{
		static private var _s_currentInstance:WindowGunControl = null;

//		private var _vm:VoxelModel;
		private var _instanceGuid:String = "";
		private var fudgeFactor:int = 30;
		static public function get currentInstance():WindowGunControl { return _s_currentInstance; }

		public function WindowGunControl( $instanceGuid:String ):void 
			{ 
				super();
				_s_currentInstance = this;
				_instanceGuid = $instanceGuid;
				
				layout.orientation = LayoutOrientation.VERTICAL;
				padding = 0;
				
				// find all the "Gun" models and add a button for each
				var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _instanceGuid );
				if ( vm )
				{
					for each ( var cm:VoxelModel in vm.modelInfo.childVoxelModels )
					{
						if ( "Gun" == cm.modelInfo.modelClass )
						{
							//var gunName:String = "";
							//if ( "Default Name" != cm.instanceInfo.name )
								//gunName = cm.instanceInfo.name
							//else 
								//gunName = cm.modelInfo.name
								
							var cannon:Button = new Button( "gunName" );
							
							cannon.width = 120;
							cannon.addEventListener(MouseEvent.CLICK, fire );
							cannon.data = cm.instanceInfo.instanceGuid;

							addElement( cannon );
						}
					}
				}
				
				autoSize = true;
				shadow = true;
				
				display( Renderer.renderer.width - (width + fudgeFactor), 322 );
		
				Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
				addEventListener(UIOEvent.REMOVED, onRemoved );
			} 

		private function fire(event:UIMouseEvent):void 
		{
			var instanceGuid:String = (event.target.data) as String;
			// Make sure this is right
			var gun:Gun = Region.currentRegion.modelCache.instanceGet( instanceGuid ) as Gun;
			WeaponEvent.dispatch( new WeaponEvent( WeaponEvent.FIRE, gun,  gun.armory.currentSelection() ) );
			

			event.target.enabled = false;
			var reloadTimer:DataTimer = new DataTimer( 5000, 1 );
			reloadTimer.label = event.target.label;
			reloadTimer.button = event.target as Button;
			event.target.label = "Reloading";
			reloadTimer.addEventListener(TimerEvent.TIMER, onRepeat);
			reloadTimer.start();
		} 

		protected function onRepeat(event:TimerEvent):void
		{
			 var tmr:DataTimer = event.currentTarget as DataTimer;
			 var button:Button = tmr.button;
			 button.label = tmr.label;
			 button.enabled = true;
		}
			
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize);
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			
			_s_currentInstance = null;
		}
		
        protected function onResize(event:Event):void
        {
			move( Renderer.renderer.width - (width + fudgeFactor), 322 );
		}
	}
	
}

import flash.utils.Timer;
import org.flashapi.swing.Button;

class DataTimer extends Timer
    {
        private var _button:Button = null;
        private var _label:String = "";

        public function DataTimer(delay:Number, repeatCount:int=0)
        {
            super(delay, repeatCount);
        }

        public function get button():Button
        {
            return _button;
        }

        public function set button(value:Button):void
        {
            _button = value;
        }
		
        public function get label():String
        {
            return _label;
        }

        public function set label(value:String):void
        {
            _label = value;
        }
    }

