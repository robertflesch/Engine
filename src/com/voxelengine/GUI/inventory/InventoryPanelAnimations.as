/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.inventory {

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.GUI.*;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.animation.Animation;

public class InventoryPanelAnimations extends VVContainer
{
    private var _listBox:ListBox;

    public function InventoryPanelAnimations($parent:VVContainer, $dataSource:String ) {
        super( $parent );
        width = _parent.width;
        //autoSize = true;
        layout.orientation = LayoutOrientation.HORIZONTAL;

        addItemContainer();
        AnimationEvent.addListener( ModelBaseEvent.RESULT, animationEvent );

        displaySelectedSource( $dataSource );
    }

    private function animationEvent( $ae:AnimationEvent ):void {
        var ani:Animation  = $ae.ani;
        _listBox.addItem( ani.name + "\t Class: " + ani.animationClass + "\t Desc: " + ani.description + "  guid: " + ani.guid, ani.guid );
    }

    private function addItemContainer():void {
        var _itemContainer:Container;
        _itemContainer = new Container( width, height );
        _itemContainer.autoSize = true;
        _itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
        addElement( _itemContainer );
        _listBox = new ListBox( width, 15 );
        _itemContainer.addElement( _listBox );
    }

    //	static public function create( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true ) : Boolean {

    private function displaySelectedSource( $dataSource:String ):void {
        _listBox.removeAll();
        if ( $dataSource == WindowInventoryNew.INVENTORY_PUBLIC )
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.PUBLIC, null, null );
        else if ( $dataSource == WindowInventoryNew.INVENTORY_OWNED )
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.userId, null, null );
        else
            AnimationEvent.create( ModelBaseEvent.REQUEST_TYPE, 0, Network.storeId, null, null );
    }


    override protected function onRemoved( event:UIOEvent ):void {
        AnimationEvent.removeListener( ModelBaseEvent.RESULT, animationEvent );
    }
}
}
