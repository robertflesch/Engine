
package com.voxelengine.GUI
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import flash.utils.Dictionary;
import flash.events.Event;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.VoxelModel;
import com.voxelengine.worldmodel.models.InstanceInfo;

public class WindowCrafting extends VVPopup
{
	private const PANEL_WIDTH:int = 200;
	private const PANEL_HEIGHT:int = 300;
	private const PANEL_BUTTON_HEIGHT:int = 200;
	
	public function WindowCrafting()
	{
		super("Voxel Models");
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		display();
		
		addEventListener(UIOEvent.REMOVED, onRemoved );
	}
		
  }
}