/**
 * Created by dev on 12/9/2016.
 */
/*==============================================================================
 Copyright 2011-2014 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI
{
import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ScriptEvent;
import com.voxelengine.events.VVWindowEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.scripts.ScriptLibrary;

import flash.events.Event;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.RegionManager;

public class WindowScriptList extends VVPopup
{
    static private const WIDTH:int = 200;
    static public const WINDOW_SCRIPT_LIST_TITLE:String = "Script List";

    static private var _s_currentInstance:WindowScriptList = null;
    static public function get isActive():Boolean { return null != _s_currentInstance; }
    static public function create( $vm:VoxelModel ):WindowScriptList
    {
        if ( null == _s_currentInstance )
            new WindowScriptList($vm);
        return _s_currentInstance;
    }

    private var _listbox1:ListBox = new ListBox( WIDTH, 15 );
    private var _vm:VoxelModel;

    public function WindowScriptList( $vm:VoxelModel )
    {
        super(WINDOW_SCRIPT_LIST_TITLE);
        _vm = $vm;
        autoSize = true;
        layout.orientation = LayoutOrientation.VERTICAL;

        addElement(new Label( "Click Script to add to model" ));
        addElement( _listbox1 );

        populate();

        // Event handlers
        eventCollector.addEvent( _listbox1, UIMouseEvent.CLICK, addScript );

        Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);

        display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
    }

    private function populate():void {
        var list:Vector.<String> = ScriptLibrary.getScripts(_vm);
        for each ( var script:String in list )
            _listbox1.addItem( script );
    }

    private function addScript(e:UIMouseEvent):void
    {
        var listBox:ListBox = e.target as ListBox;
        var item:ListItem = listBox.itemGet( listBox.selectedIndex );
        // I am missing using name here,
        // since name usually refers to a name of a script, not the type of a script
        // and here name is type
        ScriptEvent.create( ScriptEvent.SCRIPT_SELECTED, "", item.value )
        remove();
    }

    override protected function onRemoved( event:UIOEvent ):void {
        super.onRemoved( event );

        Globals.g_app.dispatchEvent( new VVWindowEvent( VVWindowEvent.WINDOW_CLOSING, label ) );
        _s_currentInstance = null;
    }

}
}
