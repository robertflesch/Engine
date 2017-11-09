/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.inventory {

import com.voxelengine.events.AnimationEvent;
import com.voxelengine.worldmodel.animation.Animation;

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;

public class InventoryPanelAnimations extends VVContainer
{
    // TODO need a more central location for these
    static public const REGION_CAT_PRIVATE:String = "Personal";
    static public const REGION_CAT_GROUP:String = "Group";
    static public const REGION_CAT_MANAGE:String = "Manage";

    private var _barUpper:TabBar;
    // This hold the items to be displayed
    private var _itemContainer:Container;
    private var _listbox1:ListBox;
    private var _dataSource:String;


    public function InventoryPanelAnimations($parent:VVContainer, $dataSource:String ) {
        super( $parent );
        _dataSource = $dataSource;
        width = _parent.width;
        //autoSize = true;
        layout.orientation = LayoutOrientation.HORIZONTAL;

//		upperTabsAdd();
        addItemContainer();
        AnimationEvent.addListener( ModelBaseEvent.RESULT, animationEvent );
        AnimationEvent.addListener( ModelBaseEvent.ADDED, animationEvent );

        displaySelectedSource( $dataSource );
    }

    private function animationEvent( $ae:AnimationEvent ):void {
        var ani:Animation  = $ae.ani;
        _listbox1.addItem( ani.name + "\t Owner: " + ani.owner + "\t Desc: " + ani.description  + "\t Class: " + ani.animationClass + "  guid: " + ani.guid, ani.guid );

    }

    private function addItemContainer():void {
        _itemContainer = new Container( width, height );
        _itemContainer.autoSize = true;
        _itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
        addElement( _itemContainer );
        _listbox1 = new ListBox( width, 15 );
        _itemContainer.addElement( _listbox1 );
    }

    //	static public function create( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true ) : Boolean {

    private function displaySelectedSource( $dataSource:String ):void {
        _listbox1.removeAll();
        if ( $dataSource == WindowInventoryNew.INVENTORY_PUBLIC )
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC, null, null );
        else if ( $dataSource == WindowInventoryNew.INVENTORY_OWNED )
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId, null, null );
        else
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.storeId, null, null );
    }


    override protected function onRemoved( event:UIOEvent ):void {
    }
}
}
