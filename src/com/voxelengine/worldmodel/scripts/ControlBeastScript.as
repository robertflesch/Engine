package com.voxelengine.worldmodel.scripts 
{
/**
 * ...
 * @author Bob
 */
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.OxelEvent;
import com.voxelengine.GUI.WindowBeastControlQuery;
import com.voxelengine.GUI.actionBars.WindowBeastControl;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class ControlBeastScript extends Script 
{
	public function ControlBeastScript() 
	{
		OxelEvent.addListener( OxelEvent.INSIDE, onInsideEvent );
		OxelEvent.addListener( OxelEvent.OUTSIDE, onOutsideEvent );
	}
	
	public function onInsideEvent( $event:OxelEvent ):void 
	{
		if ( instanceGuid != $event.instanceGuid )
		{
			//Log.out( "OnOxelEvent: ignoring event for someone else" + $event );
			return;
		}
			
		//Log.out( "ControlObjectScript.onInsideEvent: " + $event );

		if ( $event.type == OxelEvent.INSIDE )
		{
			if ( null == WindowBeastControlQuery.currentInstance && null == WindowBeastControl.currentInstance )
			{
				if ( vm )
				{
					var controllingModel:VoxelModel = vm.instanceInfo.controllingModel;
					if ( Globals.player && Globals.player.instanceInfo ) {
						var ii:InstanceInfo = Globals.player.instanceInfo;
						if ( controllingModel && null == Globals.player.instanceInfo.controllingModel )
							new WindowBeastControlQuery( controllingModel.instanceInfo.instanceGuid );
					}
					else
						Log.out( "ControlBeastScript.onInsideEvent - NO PLAYER defined" );
				}
			}
		}
	}
	
	public function onOutsideEvent( $event:OxelEvent ):void 
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
		OxelEvent.removeListener( OxelEvent.INSIDE, onInsideEvent );
		OxelEvent.removeListener( OxelEvent.OUTSIDE, onOutsideEvent );
	}
	
}

}