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
				
		public function ControlObjectScript() 
		{
			TriggerEvent.addListener( TriggerEvent.INSIDE, onInsideEvent, true, 0, true);
			TriggerEvent.addListener( TriggerEvent.OUTSIDE, onOutsideEvent, true, 0, true);
		}
		
		public function onInsideEvent( $event:TriggerEvent ):void 
		{
			if ( instanceGuid != $event.instanceGuid )
			{
				//Log.out( "OnOxelEvent: ignoring event for someone else" + $event );
				return;
			}
				
			//Log.out( "ControlObjectScript.onInsideEvent: " + $event );

			if ( $event.type == TriggerEvent.INSIDE )
			{
				if ( !WindowShipControl.currentInstance && !WindowGunControl.currentInstance )
				{
					var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( instanceGuid );
					if ( vm )
					{
						var controllingModel:VoxelModel = vm.instanceInfo.controllingModel;	
						_wt = new WindowShipControlQuery( controllingModel.instanceInfo.instanceGuid );
					}
				}
			}
		}
		
		public function onOutsideEvent( $event:TriggerEvent ):void 
		{
			if ( instanceGuid != $event.instanceGuid )
			{
				//Log.out( "ControlObjectScript.onOutsideEvent: ignoring event for someone else" + $event );
				return;
			}
				
			//Log.out( "ControlObjectScript.onOutsideEvent: " + $event );

			if ( _wt )
			{
				_wt.remove();
				_wt = null;
			}
		}
		
		override public function dispose():void { 
			TriggerEvent.addListener( TriggerEvent.INSIDE, onInsideEvent, true, 0, true);
			TriggerEvent.addListener( TriggerEvent.OUTSIDE, onOutsideEvent, true, 0, true);
		}
	}

}