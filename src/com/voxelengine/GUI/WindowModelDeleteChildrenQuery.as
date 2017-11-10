/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.makers.ModelDestroyer;
import com.voxelengine.worldmodel.models.ModelInfo;


public class WindowModelDeleteChildrenQuery extends VVPopup
{
	private var _cb:CheckBox;
	private var _modelGuid:String;
	private var _removeModelFunction:Function;
    private var _modelInfo:ModelInfo;
	
	public function WindowModelDeleteChildrenQuery( $modelGuid:String, $removeModelFunction:Function ) {
		super( LanguageManager.localizedStringGet( "ModelDelete" ) );
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
        function dataResult( $mie:ModelInfoEvent):void {
            if ( _modelGuid == $mie.modelGuid ) {
                _modelInfo = $mie.vmi;
                ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, dataResult );
                ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, dataResult );
                ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );
                deleteChildrenQuery();
            }
        }

        function dataResultFailed( $mie:ModelInfoEvent):void {
            if ( _modelGuid == $mie.modelGuid ) {
                ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, dataResult);
                ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, dataResult);
                ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, dataResultFailed );
                deleteChildrenQuery();
            }
        }
    }


	private function deleteChildrenQuery():void {
        addElement( new Spacer( width, 20 ) );
        addElement( new Label( "Are you sure you want to delete this model?" ) );
        addElement( new Label( "Click the close window (red X) button to NOT delete the model" ) );
        addElement( new Label( "Deleting this model will remove it from your inventory for all time" ) );
        addElement( new Spacer( width, 20 ) );

        if ( _modelInfo ) {
            if (_modelInfo.childVoxelModels && 0 < _modelInfo.childVoxelModels.length) {
                _cb = new CheckBox("Delete all child models too?");
                _cb.selected = true;
                addElement(_cb);
                addElement(new Spacer(width, 20));
            } else if (_modelInfo.unloadedChildCount()) {
                _cb = new CheckBox("Delete all child models too?");
                _cb.selected = true;
                addElement(_cb);
                addElement(new Spacer(width, 20));
            }
        }

        var button:Button = new Button( "Delete", 100 );
        button.autoSize = false;
        eventCollector.addEvent( button, UIMouseEvent.CLICK, deleteModelHandler );
        addElement( button );

        addElement( new Spacer( width, 20 ) );

        display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
	}

	private function deleteModelHandler( e:UIMouseEvent ):void {
        deleteModel();
    }

    private function deleteModel():void {
		// remove from inventory panel
		_removeModelFunction( _modelGuid );
		// delete from persistence
		var recursiveDelete:Boolean = _cb ? _cb.selected : false;
		new ModelDestroyer( _modelGuid, recursiveDelete );
		remove();
	}
}
}
