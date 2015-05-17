package com.voxelengine.worldmodel.scripts 
{
/**
 * ...
 * @author Bob
 */
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.TriggerEvent;
import com.voxelengine.GUI.WindowBeastControlQuery;
import com.voxelengine.GUI.actionBars.WindowBeastControl;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class ControlBeastScript extends Script 
{
	public function ControlBeastScript() 
	{
		TriggerEvent.addListener( TriggerEvent.INSIDE, onInsideEvent );
		TriggerEvent.addListener( TriggerEvent.OUTSIDE, onOutsideEvent );
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
			if ( null == WindowBeastControlQuery.currentInstance && null == WindowBeastControl.currentInstance )
			{
				if ( vm )
				{
					var controllingModel:VoxelModel = vm.instanceInfo.controllingModel;
					if ( Player.player && Player.player.instanceInfo ) {
						var ii:InstanceInfo = Player.player.instanceInfo;
						if ( controllingModel && null == Player.player.instanceInfo.controllingModel )
							new WindowBeastControlQuery( controllingModel.instanceInfo.instanceGuid );
					}
					else
						Log.out( "ControlBeastScript.onInsideEvent - NO PLAYER defined" );
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

		if ( WindowBeastControlQuery.currentInstance )
			WindowBeastControlQuery.currentInstance.remove();
		if ( WindowBeastControl.currentInstance )
			WindowBeastControl.currentInstance.remove();
	}
	
	override public function dispose():void { 
		TriggerEvent.removeListener( TriggerEvent.INSIDE, onInsideEvent );
		TriggerEvent.removeListener( TriggerEvent.OUTSIDE, onOutsideEvent );
	}
	
}

}