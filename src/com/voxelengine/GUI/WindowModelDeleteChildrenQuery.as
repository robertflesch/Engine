/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.worldmodel.models.makers.ModelDestroyer;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.Region;
import flash.events.DataEvent;
import flash.utils.ByteArray;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class WindowModelDeleteChildrenQuery extends VVPopup
{
	private var _cb:CheckBox;
	private var _modelGuid:String;
	private var _removeModelFunction:Function;
	
	public function WindowModelDeleteChildrenQuery( $modelGuid:String, $removeModelFunction:Function )
	{
		super( LanguageManager.localizedStringGet( "Model Delete" ) );
		_modelGuid = $modelGuid;
		_removeModelFunction = $removeModelFunction;

		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		addElement( new Spacer( width, 20 ) );
		addElement( new Label( "Are you sure you want to delete this model?" ) );
		addElement( new Label( "click the close window button to cancel" ) );
		_cb = new CheckBox( "Delete all child models too?" );
		_cb.selected = true;
		addElement( _cb );
		
		addElement( new Spacer( width, 20 ) );
		
		var button:Button = new Button( "Delete", 100 );
		button.autoSize = false;
		eventCollector.addEvent( button, UIMouseEvent.CLICK, deleteModel );
		addElement( button );
		
		addElement( new Spacer( width, 20 ) );
		
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function deleteModel( e:UIMouseEvent ):void
	{
		// remove from inventory panel
		_removeModelFunction( _modelGuid );
		// delete from persistance
		new ModelDestroyer( _modelGuid, _cb.selected );
		remove();
	}
}
}
