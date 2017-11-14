/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI {


import flash.events.Event;

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.VVWindowEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.weapons.Armory;
import com.voxelengine.worldmodel.models.ModelInfo;

public class PopupAmmoList extends VVPopup {
    static private const WIDTH:int = 200;
    static public const WINDOW_AMMO_LIST_TITLE:String = "Ammo List";

    static private var _s_currentInstance:PopupAmmoList = null;
    static public function get isActive():Boolean { return null != _s_currentInstance; }
    static public function create( $gunGuid:String ):PopupAmmoList {
        if ( null == _s_currentInstance )
            new PopupAmmoList($gunGuid);
        return _s_currentInstance;
    }

    private var _listBox:ListBox = new ListBox( WIDTH, 15 );
    private var _gunModelGuid:String;

    // Ammo needs to be done like scripts, there are model Scripts and instance scripts
    public function PopupAmmoList( $gunModelGuid:String )
    {
        super(WINDOW_AMMO_LIST_TITLE);
        _gunModelGuid = $gunModelGuid;
        autoSize = true;
        layout.orientation = LayoutOrientation.VERTICAL;

        addElement( new Label( "Click Ammo to add to Gun" ) );
        addElement( _listBox );

        ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoSuccess );
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _gunModelGuid, null );

        // Event handlers
        eventCollector.addEvent( _listBox, UIMouseEvent.CLICK, addScript );

        Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);

        display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
    }

    private function modelInfoSuccess( $mie:ModelInfoEvent ):void {
        if ( $mie.modelGuid == _gunModelGuid ){
            ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoSuccess );
            var mi:ModelInfo = $mie.modelInfo;
            var weaponType:String = Armory.DEFAULT_WEAPON_TYPE;
            if ( mi.dbo.gun && mi.dbo.gun.weaponType )
                weaponType = mi.dbo.gun.weaponType;
            AmmoEvent.addListener( ModelBaseEvent.RESULT, addAmmo );
            AmmoEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, weaponType, null );
        }
    }

    private function addAmmo( $ae:AmmoEvent ):void {
        _listBox.addItem( $ae.ammo.name, $ae.ammo );
    }

    private function addScript(e:UIMouseEvent):void {
        var listBox:ListBox = e.target as ListBox;
        var item:ListItem = listBox.itemGet( listBox.selectedIndex );
        AmmoEvent.create( AmmoEvent.AMMO_SELECTED, 0, _gunModelGuid, item.data );
        remove();
    }

    override protected function onRemoved( event:UIOEvent ):void {
        super.onRemoved( event );

        AmmoEvent.removeListener( ModelBaseEvent.RESULT, addAmmo );
        Globals.g_app.dispatchEvent( new VVWindowEvent( VVWindowEvent.WINDOW_CLOSING, label ) );
        _s_currentInstance = null;
    }

}
}
