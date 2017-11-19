/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.events.AmmoEvent;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.PopupAmmoList;
import com.voxelengine.worldmodel.weapons.Ammo;
import com.voxelengine.worldmodel.weapons.Armory;
import com.voxelengine.worldmodel.weapons.Gun;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelModelAmmo extends PanelBase
{
    private var _listAmmo:			    ListBox;
    private var _selectedAmmo:			Ammo;
    private var _deleteButton:				Button;
    private var _detailButton:				Button;
    private var _selectedModel:				Gun;

    public function PanelModelAmmo($parent:ContainerModelDetails, $widthParam:Number, $elementHeight:Number, $heightParam:Number )
    {
        var currentY:int = 5;
        super( $parent, $widthParam, $heightParam );
        autoHeight = false;
        layout = new AbsoluteLayout();
        var ha:Label = new Label( LanguageManager.localizedStringGet( "can_use_these_ammos" ), width );
        ha.textAlign = TextAlign.CENTER;
        ha.y = currentY;
        addElement( ha );

        _listAmmo = new ListBox(  width - 10, $elementHeight, $heightParam );
        _listAmmo.x = 5;
        _listAmmo.y = currentY = currentY + HEIGHT_BUTTON_DEFAULT - 5;
        _listAmmo.eventCollector.addEvent( _listAmmo, ListEvent.LIST_CHANGED, select );
        addElement( _listAmmo );

        const btnWidth:int = width - 10;

        var addButton:Button = new Button( LanguageManager.localizedStringGet( "Ammo_Add" )  );
        addButton.y = currentY = currentY + _listAmmo.height + 10;
        addButton.x = 5;
        addButton.eventCollector.addEvent( addButton, UIMouseEvent.CLICK, ammoAddHandler );
        addButton.width = btnWidth;
        addElement( addButton );

        _deleteButton = new Button( LanguageManager.localizedStringGet( "Ammo_Delete" ) );
        _deleteButton.y = currentY = currentY + HEIGHT_BUTTON_DEFAULT;
        _deleteButton.x = 5;
        _deleteButton.eventCollector.addEvent( _deleteButton, UIMouseEvent.CLICK, deleteAmmoHandler );
        _deleteButton.enabled = false;
        _deleteButton.width = btnWidth;
        addElement( _deleteButton );

        _detailButton = new Button( LanguageManager.localizedStringGet( "Ammo_Detail" ) );
        _detailButton.y = currentY = currentY + HEIGHT_BUTTON_DEFAULT;
        _detailButton.x = 5;
        _detailButton.eventCollector.addEvent( _detailButton, UIMouseEvent.CLICK, ammoDetailHandler );
        _detailButton.enabled = false;
        _detailButton.width = btnWidth;
        addElement( _detailButton );

        function deleteAmmoHandler(event:UIMouseEvent):void  {
            if ( _selectedAmmo ) {
                _selectedModel.armoryRemoveAmmo( _selectedAmmo );
                populateAmmos( _selectedModel );
                _selectedAmmo = null
            } else
                noAmmoSelected();
        }

        height =  currentY + HEIGHT_BUTTON_DEFAULT;

        recalc( width, height );
    }

    override public function remove():void {
        super.remove();
        _listAmmo = null;
        _selectedAmmo = null;
        _selectedModel = null;
    }

    public function populateAmmos( $vm:Gun ):void {
        _selectedModel = $vm;
        _listAmmo.removeAll();
        if ( $vm.armory ) {
            var ammory:Armory = $vm.armory;
            var ammos:Vector.<Ammo> = ammory.getAmmoList();
            for each (var ammo:Ammo in ammos) {
                _listAmmo.addItem(ammo.name, ammo);
            }
        }

        select(null);
    }

    private function select(event:ListEvent):void {
        if ( event && event.target && event.target.data )
            _selectedAmmo = event.target.data;
        else
            _selectedAmmo = null;

        if ( _selectedAmmo ) {
            _selectedModel.stateLock( false );
            _selectedModel.stateSet( _selectedAmmo.name );
            _selectedModel.stateLock( true );
//            _detailButton.enabled = true;
//            _detailButton.active = true;
            _deleteButton.enabled = true;
            _deleteButton.active = true;
        } else {
            _detailButton.enabled = false;
            _detailButton.active = false;
            _deleteButton.enabled = false;
            _deleteButton.active = false;
        }
    }


    private function ammoDetailHandler(event:UIMouseEvent):void {
//        new PopupAmmoDetail( _selectedAmmo );
    }

    private function ammoAddHandler(event:UIMouseEvent):void {
        AmmoEvent.addListener( AmmoEvent.AMMO_SELECTED, ammoAddedEvent );
        new PopupAmmoList( _selectedModel.modelInfo.guid );
    }

    private function ammoAddedEvent( $ae:AmmoEvent ):void {
        AmmoEvent.removeListener( AmmoEvent.AMMO_SELECTED, ammoAddedEvent );
        _selectedModel.armoryAddAmmo( $ae.ammo );
        populateAmmos( _selectedModel );
    }

    ///////////////////////////////////////////////////////////////////////

    private function noAmmoSelected():void {
        (new Alert( LanguageManager.localizedStringGet( "no_ammo_selected" ) )).display();
    }

}
}