/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI {
import com.voxelengine.GUI.components.ComponentCheckBox;
import com.voxelengine.GUI.components.ComponentComboBoxWithLabel;
import com.voxelengine.GUI.components.ComponentLabelInput;
import com.voxelengine.worldmodel.TypeInfo;

import flash.display.Bitmap;
import flash.display.BitmapData;


import flash.display.Loader;

import flash.events.Event;

import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.constants.LayoutOrientation;

import org.flashapi.swing.databinding.DataProvider;

import org.flashapi.swing.event.ButtonsGroupEvent;

import org.flashapi.swing.event.ListEvent;
import org.flashapi.swing.event.TextEvent;

import org.flashapi.swing.event.UIMouseEvent;

import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.*;

import com.voxelengine.Globals;

import org.flashapi.swing.list.ListItem;

public class WindowPictureImport extends VVPopup {
    private var _pictureStyle:int = TypeInfo.GLASS;
    private var _container:AdjustablePictureBox;
    public function WindowPictureImport() {
        super("Window Picture Import");
        width = 256;
        height = 500;
        layout.orientation = LayoutOrientation.VERTICAL;
/*
        var b1:Button = new Button( "Stained Glass Style");
        addElement( b1 );
        var b2:Button = new Button( "Mural Style");
        addElement( b2 );
        */

        var box1:VVBox = new VVBox( width );
        box1.layout.orientation = LayoutOrientation.VERTICAL;
        box1.addElement( new Label( "Picture Style") );
        var rbGroup:RadioButtonGroup = new RadioButtonGroup( box1 );
        var radioButtons:DataProvider = new DataProvider();
        radioButtons.addAll( { label:"Stained Glass Style (semi-transparent)", data:TypeInfo.GLASS }
                           , { label:"Mural Style (opaque)", data:TypeInfo.WHITE } );
        eventCollector.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED
                , function (event:ButtonsGroupEvent):void {  _pictureStyle = (0 == event.target.index ?  TypeInfo.GLASS : TypeInfo.WHITE) } );
        rbGroup.dataProvider = radioButtons;
        rbGroup.index = 0;
        addElement( box1 );
        var cb:ComponentCheckBox = new ComponentCheckBox("Remove Transparent Pixels", true, width * 1.4, toggleRemoveTransparent );
        addElement( cb );

        var values:Vector.<String> = new Vector.<String>();
        values.push("1");
        values.push("2");
        values.push("3");
        values.push("4");
        var data:Vector.<int> = new Vector.<int>();
        data.push(1);
        data.push(2);
        data.push(3);
        data.push(4);
        
        addElement( new ComponentComboBoxWithLabel( "Size in meters"
                , pictureSize
                , values[0]
                , values
                , data
                , width ) );


        var li:ComponentLabelInput = new ComponentLabelInput( "URL of photo", urlChanged, "", width );
        addElement( li);
        addElement( new Spacer( width, 10 ) );
        //_container = new VVBox(255,255);
        _container = new AdjustablePictureBox(255,255, null );
        addElement( _container );

        addElement( new Spacer( width, 10 ) );

        var but:Button = new Button( "Create", width, 35 );
        $evtColl.addEvent( but, UIMouseEvent.CLICK, createHandler );
        addElement( but );

        eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
        display(30, 30);
    }

    private function urlChanged( $te:TextEvent ):void {
        var urlRequest:URLRequest = new URLRequest( $te.target.label );
        var urlLoader:URLLoader = new URLLoader();
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        urlLoader.addEventListener(Event.COMPLETE, urlLoader_complete);
        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_error);
        urlLoader.load(urlRequest);

        function urlLoader_complete($event:Event):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, function(e:Event):void {
                var bmpData:BitmapData = new BitmapData(e.target.width,e.target.height);
                bmpData.draw(loader);
                _container.addPicture( bmpData );
            });
            loader.loadBytes($event.target.data);


            //_container.backgroundTexture = $te.target.label;
        }

        function urlLoader_error(evt:IOErrorEvent):void {
            trace("file obviously not found");
        }
    }

    private function createHandler( $me:UIMouseEvent ):void {

    }

    private function pictureSize( $le:ListEvent ):void {
        var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex )
        trace("pictureSize");
    }
    
    private function toggleRemoveTransparent( $me:UIMouseEvent ):void {
        trace("transparent");

    }
    private function onRemoved( event:UIOEvent ):void {
            trace("OVer");
    }
}
}

