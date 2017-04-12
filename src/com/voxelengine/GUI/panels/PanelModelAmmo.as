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

import org.flashapi.swing.layout.AbsoluteLayout;

//import com.voxelengine.GUI.WindowammoList;
//import com.voxelengine.GUI.voxelModels.WindowammoDetail;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.worldmodel.weapons.Armory;
import com.voxelengine.worldmodel.weapons.Gun;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModelAmmo extends PanelBase
{
    private var _listammos:			    ListBox;
    private var _selectedAmmo:			Ammo;
    private var _buttonContainer:			Container;
    private var _addButton:					Button;
    private var _deleteButton:				Button;
    private var _detailButton:				Button;
    private var _selectedModel:				Gun;
    private var _currentY:                  int;

    public function PanelModelAmmo($parent:PanelModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
    {
        super( $parent, $widthParam, $heightParam );
        autoHeight = false;
        layout = new AbsoluteLayout();
        _currentY = 5;
        var ha:Label = new Label( "Has these Ammos", width );
        ha.textAlign = TextAlign.CENTER;
        ha.y = _currentY;
        addElement( ha );

        _listammos = new ListBox(  width - 10, $elementHeight, $heightParam );
        _listammos.x = 5;
        _listammos.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT - 5;
        _listammos.eventCollector.addEvent( _listammos, ListEvent.LIST_CHANGED, select );
        addElement( _listammos );

        const btnWidth:int = width - 10;

        _addButton = new Button( LanguageManager.localizedStringGet( "Ammo_Add" )  );
        _addButton.y = _currentY = _currentY + _listammos.height + 10;
        _addButton.x = 5;
        _addButton.eventCollector.addEvent( _addButton, UIMouseEvent.CLICK, ammoAddHandler );
        _addButton.width = btnWidth;
        addElement( _addButton );

        _deleteButton = new Button( LanguageManager.localizedStringGet( "Ammo_Delete" ) );
        _deleteButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
        _deleteButton.x = 5;
        _deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteAmmoHandler );
        _deleteButton.enabled = false;
        _deleteButton.width = btnWidth;
        addElement( _deleteButton );

        _detailButton = new Button( LanguageManager.localizedStringGet( "Ammo_Detail" ) );
        _detailButton.y = _currentY = _currentY + HEIGHT_BUTTON_DEFAULT;
        _detailButton.x = 5;
        _detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, ammoDetailHandler );
        _detailButton.enabled = false;
        _detailButton.width = btnWidth;
        addElement( _detailButton );

        function deleteAmmoHandler(event:UIMouseEvent):void  {
            if ( _selectedAmmo )
            {
                var ammory:Armory = (_selectedModel as Gun).armory;
                var ammos:Vector.<Ammo> = ammory.getAmmoList();
                for ( var i:int = 0; i < ammos.length; i++ ){
                    if ( _selectedAmmo == ammos[i] ) {
                        //ammos[i].dispose();
                        ammos[i] = null;
                        ammos.splice( i, 1 );
                    }
                }
                populateAmmos( _selectedModel );
                // these are instance ammos, not model ammos.
                //_selectedModel.modelInfo.changed = true;
                Region.currentRegion.changed = true;
                RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null );
            }
            else
                noAmmoSelected();
        }

        height =  _currentY + HEIGHT_BUTTON_DEFAULT;

        recalc( width, height );
    }

    override public function close():void {
        super.close();
        _listammos = null;
        _selectedAmmo = null;
        _buttonContainer = null;
        _selectedModel = null;
    }

    public function populateAmmos( $vm:Gun ):void
    {
        _selectedModel = $vm;
        _listammos.removeAll();
        if ( $vm.armory ) {
            var ammory:Armory = $vm.armory;
            var ammos:Vector.<Ammo> = ammory.getAmmoList();
            for each (var ammo:Ammo in ammos) {
                _listammos.addItem(ammo.name, ammo);
            }
        }

        select(null);
    }

    private function select(event:ListEvent):void
    {
        if ( event && event.target && event.target.data )
            _selectedAmmo = event.target.data;
        else
            _selectedAmmo = null;

        if ( _selectedAmmo )
        {
            _selectedModel.stateLock( false );
            _selectedModel.stateSet( _selectedAmmo.name );
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


    private function ammoDetailHandler(event:UIMouseEvent):void {
//        new WindowammoDetail( _selectedAmmo );
    }

    private function ammoAddHandler(event:UIMouseEvent):void {
//        ammoEvent.addListener( ammoEvent.ammo_SELECTED, ammoSelected );
//        new WindowammoList( _selectedModel );
    }

    ///////////////////////////////////////////////////////////////////////

    private function noAmmoSelected():void {
        (new Alert( LanguageManager.localizedStringGet( "No_ammo_Selected" ) )).display();
    }

    private function ammoSelected(se:AmmoEvent):void {
        // I am misusing se.name here, name is really the 'type'
//        var addedammo:ammo = _selectedModel.instanceInfo.addammo( se.name, false);
//        _listammos.addItem(  se.name, addedammo );
//        RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid, null );
    }
}
}