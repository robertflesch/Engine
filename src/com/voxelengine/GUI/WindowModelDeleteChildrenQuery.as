/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.ModelInfo;
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

		// request the ModelData so that we can get the modelInfo from it.
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, dataResult );
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, dataResult );
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );

		// make sure everything is saved BEFORE we delete, otherwise the save can come AFTER the delete
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.SAVE, 0, "", null ) );

		// now request the modelInfo
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) );
	}

	private function dataResultFailed( $mie:ModelInfoEvent):void {
		var miGuid:String = $mie.modelGuid;
		var mi:ModelInfo = $mie.vmi;
		if ( _modelGuid == $mie.modelGuid ) {
			ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, dataResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, dataResult);


			addElement( new Spacer( width, 20 ) );
			addElement( new Label( "You do not have permission to delete this model OR" ) );
			addElement( new Label( "We are unable to find all of the info needed to delete this model" ) );
			addElement( new Label( "The app will clean up what it can" ) );
			addElement( new Label( "Click the close window (red X) button to cancel" ) );
			addElement( new Spacer( width, 20 ) );

			ModelMetadataEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
			OxelDataEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
			// This too?
			//ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.DELETE, 0, _modelGuid, null ) );

			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
		}
	}

	private function dataResult( $mie:ModelInfoEvent):void {
		var miGuid:String = $mie.modelGuid;
		var mi:ModelInfo = $mie.vmi;
		if ( _modelGuid == $mie.modelGuid ) {
			ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, dataResult );
			ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, dataResult );


			addElement( new Spacer( width, 20 ) );
			addElement( new Label( "Are you sure you want to delete this model?" ) );
			addElement( new Label( "click the close window (red X) button to not delete the model" ) );
			addElement( new Spacer( width, 20 ) );

			if ( mi.childVoxelModels && 0 < mi.childVoxelModels.length ) {
				_cb = new CheckBox("Delete all child models too?");
				_cb.selected = true;
				addElement(_cb);
				addElement( new Spacer( width, 20 ) );
			}

			var button:Button = new Button( "Delete", 100 );
			button.autoSize = false;
			eventCollector.addEvent( button, UIMouseEvent.CLICK, deleteModel );
			addElement( button );

			addElement( new Spacer( width, 20 ) );

			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
		}
	}

	private function deleteModel( e:UIMouseEvent ):void {
		// remove from inventory panel
		_removeModelFunction( _modelGuid );
		// delete from persistance
		var recursiveDelete:Boolean = _cb ? _cb.selected : false;
		new ModelDestroyer( _modelGuid, recursiveDelete );

		remove();
	}
}
}
