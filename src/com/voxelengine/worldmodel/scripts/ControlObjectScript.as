/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.scripts
{
	/**
	 * ...
	 * @author Bob
	 */
	import com.voxelengine.Globals;
	import com.voxelengine.GUI.actionBars.WindowShipControl;
	import com.voxelengine.GUI.actionBars.WindowGunControl;
	import com.voxelengine.GUI.WindowShipControlQuery;
	import com.voxelengine.worldmodel.scripts.Script;
	import com.voxelengine.events.TriggerEvent;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	public class ControlObjectScript extends Script 
	{
		private var _wt:WindowShipControlQuery = null;
				
		public function ControlObjectScript( $params:Object ) {
			super( $params );
			Log.out( "ControlObjectScript - Adding trigger events" );
			TriggerEvent.addListener( TriggerEvent.INSIDE, onInsideEvent); //, true, 0, true);
			TriggerEvent.addListener( TriggerEvent.OUTSIDE, onOutsideEvent); //, true, 0, true);
		}
		
		public function onInsideEvent( $event:TriggerEvent ):void 
		{
			if ( instanceGuid != $event.instanceGuid ) {
				//Log.out( "OnOxelEvent: ignoring event for someone else" + $event );
				return;
			}
				
			//Log.out( "ControlObjectScript.onInsideEvent: " + $event );

			if ( !WindowShipControl.currentInstance && !WindowGunControl.currentInstance ) {
				var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( instanceGuid );
				if ( vm ) {
					var controllingModel:VoxelModel = vm.instanceInfo.controllingModel;
					if ( controllingModel && null == _wt )
						_wt = new WindowShipControlQuery( controllingModel.instanceInfo.instanceGuid );
					else
						Log.out( "ControlObjectScript.OnInsideEvent - No controlling model for this script" );
				}
				else
					Log.out( "ControlObjectScript.OnInsideEvent - Unable to find this trigger in model cache" );
			}
		}
		
		public function onOutsideEvent( $event:TriggerEvent ):void 
		{
			if ( instanceGuid != $event.instanceGuid ) {
				//Log.out( "ControlObjectScript.onOutsideEvent: ignoring event for someone else" + $event );
				return;
			}
				
			//Log.out( "ControlObjectScript.onOutsideEvent: " + $event );

			if ( _wt ) {
				_wt.remove();
				_wt = null;
			}
		}
		
		override public function dispose():void {
			Log.out( "ControlObjectScript - removing trigger events" );
			TriggerEvent.removeListener( TriggerEvent.INSIDE, onInsideEvent );
			TriggerEvent.removeListener( TriggerEvent.OUTSIDE, onOutsideEvent );
		}
	}

}