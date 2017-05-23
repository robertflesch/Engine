/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI {

import com.voxelengine.utils.StringUtils;

import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;

import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.constants.LayoutOrientation;
import org.flashapi.swing.constants.TextAlign;
import org.flashapi.swing.databinding.DataProvider;
import org.flashapi.swing.*;
import org.flashapi.swing.event.ButtonsGroupEvent;
import org.flashapi.swing.event.ListEvent;
import org.flashapi.swing.event.TextEvent;
import org.flashapi.swing.event.UIMouseEvent;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.GUI.components.ComponentCheckBox;
import com.voxelengine.GUI.components.ComponentComboBoxWithLabel;
import com.voxelengine.worldmodel.TypeInfo;

public class WindowPictureImport extends VVPopup {
    private var _container:AdjustablePictureBox;
    private var _cb:ComponentCheckBox;
    private var _pti:TextInput;
    private var _plbl:Label;

    public function WindowPictureImport() {
        super("Picture Import");
        width = 256;
        height = 550;
        padding = 2;
        layout.orientation = LayoutOrientation.VERTICAL;

        var box1:VVBox = new VVBox( width-4 );
        box1.layout.orientation = LayoutOrientation.VERTICAL;
        box1.addElement( new Label( "Picture Style") );
        var rbGroup:RadioButtonGroup = new RadioButtonGroup( box1 );
        var radioButtons:DataProvider = new DataProvider();
        radioButtons.addAll( { label:"Stained Glass Style (semi-transparent)", data:TypeInfo.GLASS }
                           , { label:"Mural Style (opaque)", data:TypeInfo.WHITE } );
        rbGroup.dataProvider = radioButtons;
        $evtColl.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED, styleChanged );
        addElement( box1 );

        addPixelOptions();

        // Set radio button index this after pixel options have been added
        rbGroup.index = 0;

        var lbl:Label = new Label( "URL of image", width );
        lbl.textAlign = TextAlign.CENTER;
        lbl.textFormat.size = 12;
        addElement( lbl );

        var ti:TextInput = new TextInput( "", width-4 );
        $evtColl.addEvent( ti, TextEvent.EDITED, urlChanged );
        addElement( ti );

        addElement( new Spacer( width, 10 ) );

        var lblPre:Label = new Label( "Preview", width );
        lblPre.textAlign = TextAlign.CENTER;
        lblPre.textFormat.size = 12;
        addElement( lblPre );

        _container = new AdjustablePictureBox(width-4,width-4 );
        addElement( _container );

        addElement( new Spacer( width, 10 ) );

        var values:Vector.<String> = new Vector.<String>();
        values.push("2");
        values.push("3");
        values.push("4");
        var data:Vector.<int> = new Vector.<int>();
        data.push(2);
        data.push(3);
        data.push(4);

        addElement( new ComponentComboBoxWithLabel( "Size in meters"
                , pictureSize
                , values[0]
                , values
                , data
                , width ) );

        addElement( new Spacer( width, 10 ) );

        var but:Button = new Button( "Create", width-4, 35 );
        $evtColl.addEvent( but, UIMouseEvent.CLICK, createHandler );
        addElement( but );

        display(30, 30);
    }

    private function styleChanged( event:ButtonsGroupEvent ):void {
        if ( 0 == event.target.index ){
            PictureImportProperties.pictureStyle = TypeInfo.GLASS;
            enableDisablePixelOptions( true );
        } else if ( 1 == event.target.index ) {
            PictureImportProperties.pictureStyle = TypeInfo.WHITE;
            enableDisablePixelOptions( false );
        }
    }

    private function enableDisablePixelOptions( $state:Boolean ): void {
        _cb.visible = $state;
        _pti.visible = $state;
        _plbl.visible = $state;
    }

    private function addPixelOptions():void {
        var tContainer:Container = new Container( width, 30);
        tContainer.layout = new AbsoluteLayout();

        _cb = new ComponentCheckBox("Remove Transparent Pixels", PictureImportProperties.removeTransPixels, width * 1.4, toggleRemoveTransparent);
        tContainer.addElement(_cb);

        _pti = new TextInput("", 44);
        _pti.x = 206;
        _pti.y = 4;
        _pti.text = StringUtils.zeroPad( PictureImportProperties.transColor, 6, 16 );
        $evtColl.addEvent( _pti, TextEvent.EDITED, transChanged );
        tContainer.addElement( _pti );

        _plbl = new Label("Color 0x", 44);
        _plbl.textAlign = TextAlign.RIGHT;
        _plbl.x = 162;
        _plbl.y = 4;
        tContainer.addElement( _plbl );

        addElement(tContainer);
    }

    private function transChanged( $te:TextEvent ):void {
        var transColorST:String = $te.target.text;
        var transColor:uint = parseInt( transColorST );
        PictureImportProperties.transColor = transColor;
    }

    private function urlChanged( $te:TextEvent ):void {
        trace("WindowPictureImport.urlChanged $te: " + $te.type );
        var urlRequest:URLRequest = new URLRequest( $te.target.text );
        var urlLoader:URLLoader = new URLLoader();
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        urlLoader.addEventListener(Event.COMPLETE, urlLoader_complete);
        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_error);
        urlLoader.load(urlRequest);

        function urlLoader_complete($event:Event):void {
            var loader:Loader = new Loader();
            // INIT is needed to handle async aspect of loader
            loader.contentLoaderInfo.addEventListener(Event.INIT, function(e:Event):void {
                var bmpData:BitmapData = new BitmapData(e.target.width,e.target.height);
                bmpData.draw(loader);
                _container.addPicture( bmpData );
            });
            loader.loadBytes($event.target.data);
        }

        function urlLoader_error(evt:IOErrorEvent):void {
            trace("file obviously not found");
        }
    }

    private function createHandler( $me:UIMouseEvent ):void {
        trace("createHandler: " + PictureImportProperties.oxelSize);
        PictureImportProperties.finalBitmapData = _container.finalPicture();
    }

    private function pictureSize( $le:ListEvent ):void {
        var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex );
        PictureImportProperties.oxelSize = li.data;
        trace("pictureSize: " + PictureImportProperties.oxelSize);
    }
    
    private function toggleRemoveTransparent( $me:UIMouseEvent ):void {
        PictureImportProperties.removeTransPixels = ($me.target as CheckBox).selected;
    }
}
}

