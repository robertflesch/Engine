/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.GUI.panels
{
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.WindowScriptList;
import com.voxelengine.GUI.voxelModels.WindowScriptDetail;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ScriptEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.scripts.Script;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModelScripts extends PanelBase
{
    private var _listScripts:			    ListBox;
    private var _selectedScript:			Script;
    private var _buttonContainer:			Container;
    private var _addButton:					Button;
    private var _deleteButton:				Button;
    private var _detailButton:				Button;
    private var _selectedModel:				VoxelModel;

    public function PanelModelScripts($parent:PanelModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
    {
        super( $parent, $widthParam, $heightParam );

        var ha:Label = new Label( "Has Scripts", width );
        ha.textAlign = TextAlign.CENTER;
        addElement( ha );

        _listScripts = new ListBox(  width - pbPadding, $elementHeight, $heightParam );
        _listScripts.eventCollector.addEvent( _listScripts, ListEvent.LIST_CHANGED, select );
        addElement( _listScripts );

        ScriptButtonsCreate();
        //addEventListener( UIMouseEvent.ROLL_OVER, rollOverHandler );
        //addEventListener( UIMouseEvent.ROLL_OUT, rollOutHandler );

        recalc( width, height );
    }

    override public function close():void {
        super.close();
        _listScripts = null;
        _selectedScript = null;
        _buttonContainer = null;
        _selectedModel = null;
    }

    private function rollOverHandler(e:UIMouseEvent):void
    {
        if ( null == _buttonContainer )
            ScriptButtonsCreate();
    }

    private function rollOutHandler(e:UIMouseEvent):void
    {
        if ( null != _buttonContainer ) {
            _buttonContainer.remove();
            _buttonContainer = null;
        }
    }

    public function populateScripts( $vm:VoxelModel ):void
    {
        _selectedModel = $vm;
        _listScripts.removeAll();
//        if ( $vm.modelInfo.scripts ) {
//            var anims:Array = $vm.modelInfo.scripts;
//            for each (var anim:Script in anims) {
//                _listScripts.addItem(anim.name, anim);
//            }
//        }
        if ( $vm.instanceInfo.scripts ) {
            var scripts:Array = $vm.instanceInfo.scripts;
            for each (var anim:Script in scripts) {
                _listScripts.addItem(anim.name, anim);
            }
        }

        select(null);
    }

    // FIXME This would be much better with drag and drop
    private function ScriptButtonsCreate():void {
        //Log.out( "PanelModelScripts.ScriptButtonsCreate - width: " + width + "  height: " + height );
        _buttonContainer = new Container( width, 100 );
        _buttonContainer.layout.orientation = LayoutOrientation.VERTICAL;
        _buttonContainer.padding = 2;
        _buttonContainer.height = 0;

        addElement( _buttonContainer );

        _addButton = new Button( LanguageManager.localizedStringGet( "Script_Add" )  );
        _addButton.eventCollector.addEvent( _addButton, UIMouseEvent.CLICK, scriptAddHandler );
        _addButton.width = width - 2 * pbPadding;
        _buttonContainer.addElement( _addButton );
        _buttonContainer.height += _addButton.height + pbPadding;

        _deleteButton = new Button( LanguageManager.localizedStringGet( "Script_Delete" ) );
        _deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteScriptHandler );
        _deleteButton.enabled = false;
        _deleteButton.active = false;
        _deleteButton.width = width - 2 * pbPadding;
        _buttonContainer.addElement( _deleteButton );
        _buttonContainer.height += _deleteButton.height + pbPadding;

        _detailButton = new Button( LanguageManager.localizedStringGet( "Script_Detail" ) );
        _detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, scriptDetailHandler );
        _detailButton.enabled = false;
        _detailButton.active = false;
        _detailButton.width = width - 2 * pbPadding;
        _buttonContainer.addElement( _detailButton );

        function deleteScriptHandler(event:UIMouseEvent):void  {
            if ( _selectedScript )
            {
                var scripts:Array = _selectedModel.instanceInfo.scripts;
                for ( var i:int; i < scripts.length; i++ ){
                    if ( _selectedScript == scripts[i] ) {
                        scripts[i].dispose();
                        scripts[i] = null;
                        scripts.splice( i, 1 );
                    }
                }
                populateScripts( _selectedModel );
                // these are instance scripts, not model scripts.
                //_selectedModel.modelInfo.changed = true;
                Region.currentRegion.changed = true;
                Region.currentRegion.save();
            }
            else
                noScriptSelected();
        }
        //Log.out( "PanelModelScripts.ScriptButtonsCreate AFTER - width: " + width + "  height: " + height + " buttoncontainer - AFTER - width: " + _buttonContainer.width + "  height: " + _buttonContainer.height );
    }

    private function select(event:ListEvent):void
    {
        if ( event && event.target && event.target.data )
            _selectedScript = event.target.data;
        else
            _selectedScript = null;

        if ( _selectedScript )
        {
            _selectedModel.stateLock( false );
            _selectedModel.stateSet( _selectedScript.name );
            _selectedModel.stateLock( true );
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
        new WindowScriptList( _selectedModel );
    }

    ///////////////////////////////////////////////////////////////////////

    private function noScriptSelected():void {
        (new Alert( LanguageManager.localizedStringGet( "No_Script_Selected" ) )).display();
    }

    private function scriptSelected(se:ScriptEvent):void {
        // I am misusing se.name here, name is really the 'type'
        var addedScript:Script = _selectedModel.instanceInfo.addScript( se.name, false);
        _listScripts.addItem(  se.name, addedScript );
        Region.currentRegion.save();
    }
}
}