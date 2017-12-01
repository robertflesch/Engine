/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.panels
{
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.WindowScriptList;
import com.voxelengine.GUI.voxelModels.WindowScriptDetail;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.ScriptEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.scripts.Script;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import org.flashapi.swing.layout.AbsoluteLayout;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModelScripts extends PanelBase
{
    private var _listScripts:			    ListBox;
    private var _selectedScript:			Script;
    private var _deleteButton:				Button;
    private var _detailButton:				Button;

    public function PanelModelScripts($parent:ContainerModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
    {
        super( $parent, $widthParam, $heightParam );
        autoHeight = false;
        layout = new AbsoluteLayout();
        var _currentY:int = 5;
        var ha:Label = new Label( "Has these Spells", width );
        ha.textAlign = TextAlign.CENTER;
        ha.y = _currentY;
        addElement( ha );

        _listScripts = new ListBox(  width - 10, $elementHeight, $heightParam );
        _listScripts.x = 5;
        _listScripts.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT - 5;
        _listScripts.eventCollector.addEvent( _listScripts, ListEvent.LIST_CHANGED, select );
        addElement( _listScripts );

        const btnWidth:int = width - 10;

        var _addButton:					Button;
        _addButton = new Button( LanguageManager.localizedStringGet( "Script_Add" )  );
        _addButton.y = _currentY = _currentY + _listScripts.height + 10;
        _addButton.x = 5;
        _addButton.eventCollector.addEvent( _addButton, UIMouseEvent.CLICK, scriptAddHandler );
        _addButton.width = btnWidth;
        addElement( _addButton );

        _deleteButton = new Button( LanguageManager.localizedStringGet( "Script_Delete" ) );
        _deleteButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
        _deleteButton.x = 5;
        _deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteScriptHandler );
        _deleteButton.enabled = false;
        _deleteButton.width = btnWidth;
        addElement( _deleteButton );

        _detailButton = new Button( LanguageManager.localizedStringGet( "Script_Detail" ) );
        _detailButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
        _detailButton.x = 5;
        _detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, scriptDetailHandler );
        _detailButton.enabled = false;
        _detailButton.width = btnWidth;
        addElement( _detailButton );

        function deleteScriptHandler(event:UIMouseEvent):void  {
            if ( _selectedScript )
            {
                var scripts:Array = (_parent as ContainerModelDetails).selectedModel.instanceInfo.scripts;
                for ( var i:int = 0; i < scripts.length; i++ ){
                    if ( _selectedScript == scripts[i] ) {
                        scripts[i].dispose();
                        scripts[i] = null;
                        scripts.splice( i, 1 );
                    }
                }
                populateScripts( (_parent as ContainerModelDetails).selectedModel );
                // these are instance scripts, not model scripts.
                //_selectedModel.modelInfo.changed = true;
                Region.currentRegion.changed = true;
                RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null );
            }
            else
                noScriptSelected();
        }

        height =  _currentY + HEIGHT_BUTTON_DEFAULT + 10;

        recalc( width, height );
    }

    override public function remove():void {
        super.remove();
        ScriptEvent.removeListener( ScriptEvent.SCRIPT_SELECTED, scriptSelected );
        _listScripts.removeAll();
        _listScripts = null;
        _selectedScript = null;
    }

    public function populateScripts( $vm:VoxelModel ):void
    {
        _listScripts.removeAll();
        if ( $vm.instanceInfo.scripts ) {
            var scripts:Array = $vm.instanceInfo.scripts;
            for each (var anim:Script in scripts) {
                _listScripts.addItem(anim.name, anim);
            }
        }

        select(null);
    }

    private function select(event:ListEvent):void
    {
        if ( event && event.target && event.target.data )
            _selectedScript = event.target.data;
        else
            _selectedScript = null;

        if ( _selectedScript )
        {
            (_parent as ContainerModelDetails).selectedModel.stateLock( false );
            (_parent as ContainerModelDetails).selectedModel.stateSet( _selectedScript.name );
            (_parent as ContainerModelDetails).selectedModel.stateLock( true );
            _detailButton.enabled = true;
            _detailButton.active = true;
            _deleteButton.enabled = true;
            _deleteButton.active = true;
        }
        else {
            _detailButton.enabled = false;
            _detailButton.active = false;
            _deleteButton.enabled = false;
            _deleteButton.active = false;
        }
    }


    private function scriptDetailHandler(event:UIMouseEvent):void {
        new WindowScriptDetail( _selectedScript );
    }

    private function scriptAddHandler(event:UIMouseEvent):void {
        ScriptEvent.addListener( ScriptEvent.SCRIPT_SELECTED, scriptSelected );
        new WindowScriptList( (_parent as ContainerModelDetails).selectedModel );
    }

    ///////////////////////////////////////////////////////////////////////

    static private function noScriptSelected():void {
        (new Alert( LanguageManager.localizedStringGet( "No_Script_Selected" ) )).display();
    }

    private function scriptSelected(se:ScriptEvent):void {
        // I am misusing se.name here, name is really the 'type'
        var addedScript:Script = (_parent as ContainerModelDetails).selectedModel.instanceInfo.addScript( se.name, false);
        _listScripts.addItem(  se.name, addedScript );
        RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null );
    }
}
}