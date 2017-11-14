/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI {

import com.voxelengine.GUI.components.VVTextInput;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.utils.ColorUtils;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;


import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.geom.Matrix;
import flash.geom.Vector3D;
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
import org.flashapi.swing.event.UIOEvent;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.GUI.components.ComponentCheckBox;
import com.voxelengine.GUI.components.ComponentComboBoxWithLabel;
import com.voxelengine.worldmodel.TypeInfo;

public class WindowPictureImport extends VVPopup {
    private var _container:AdjustablePictureBox;
    private var _ccbl:ComponentComboBoxWithLabel;

    private var iContainer:VVBox;
    private var pContainer:VVBox;

    public function WindowPictureImport() {
        super( LanguageManager.localizedStringGet( "Picture Import" ));
        width = 256;
        autoHeight = true;
        padding = 2;
        layout.orientation = LayoutOrientation.VERTICAL;

        var box1:VVBox = new VVBox( width-4 );
        box1.layout.orientation = LayoutOrientation.VERTICAL;
        box1.addElement( new Label( "Picture Style") );
        var rbGroup:RadioButtonGroup = new RadioButtonGroup( box1 );
        var radioButtons:DataProvider = new DataProvider();
        radioButtons.addAll( { label:"Stained Glass Style (semi-transparent)", data:TypeInfo.CUSTOM_GLASS }
                           , { label:"Mural Style (opaque)", data:TypeInfo.WHITE } );
        rbGroup.dataProvider = radioButtons;
        $evtColl.addEvent( rbGroup, ButtonsGroupEvent.GROUP_CHANGED, styleChanged );
        addElement( box1 );

        addPixelOptions();
        addIronOptions();

        // Set radio button index this after pixel options have been added
        rbGroup.index = 0;

        var lbl:Label = new Label( "URL of image", width );
        lbl.textAlign = TextAlign.CENTER;
        lbl.textFormat.size = 12;
        addElement( lbl );

        var ti:TextInput = new VVTextInput( "", width-4 );
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
        values.push("1");
        values.push("2");
        values.push("4");
        values.push("8");
        var data:Vector.<int> = new Vector.<int>();
        data.push(4);
        data.push(5);
        data.push(6);
        data.push(7);

        _ccbl = new ComponentComboBoxWithLabel( "Size in meters"
                                              , pictureSize
                                              , values[0]
                                              , values
                                              , data
                                              , width );
        addElement( _ccbl );

        addElement( new Spacer( width, 10 ) );

        var but:Button = new Button( "Create", width-4, 35 );
        $evtColl.addEvent( but, UIMouseEvent.CLICK, createHandler );
        addElement( but );

        display(30, 30);
        $evtColl.addEvent( this, UIOEvent.REMOVED, onRemoved );
    }

    private function styleChanged( event:ButtonsGroupEvent ):void {
        if ( 0 == event.target.index ){
            PictureImportProperties.pictureStyle = TypeInfo.CUSTOM_GLASS;
            PictureImportProperties.hasTransparency = true;
            enableDisablePixelOptions( true );
            enableDisableIronOptions( true );
        } else if ( 1 == event.target.index ) {
            PictureImportProperties.pictureStyle = TypeInfo.WHITE;
            PictureImportProperties.hasTransparency = false;
            enableDisablePixelOptions( false );
            enableDisableIronOptions( false );
        }
    }

    private function enableDisableIronOptions( $state:Boolean ): void {
        iContainer.visible = $state;
    }

    private function addIronOptions():void {
        iContainer = new VVBox(width-4, 30);
        iContainer.autoHeight = true;
        iContainer.layout.orientation = LayoutOrientation.VERTICAL;

        var ccb:ComponentCheckBox = new ComponentCheckBox("Replace Black with Iron", PictureImportProperties.replaceBlackWithIron, width * 1.4, toggleReplaceBlackWithIron);
        iContainer.addElement(ccb);

        var values:Vector.<String> = new Vector.<String>();
        values.push("lots (0x11)");
        values.push("a little (0x05)");
        values.push("pitch black (0x00)");
        var data:Vector.<int> = new Vector.<int>();
        data.push(0x11);
        data.push(0x05);
        data.push(0x00);

        var ccbl:ComponentComboBoxWithLabel;
        ccbl = new ComponentComboBoxWithLabel( "Black Tolerance"
                , blackTolerance
                , values[0]
                , values
                , data
                , width - 10 );
        iContainer.addElement( ccbl );

        addElement(iContainer);

        function toggleReplaceBlackWithIron($me:UIMouseEvent):void {
            PictureImportProperties.replaceBlackWithIron = ($me.target as CheckBox).selected;
        }

        function blackTolerance( $le:ListEvent ):void {
            var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex );
            PictureImportProperties.blackColor = li.data;
        }
    }

    private function enableDisablePixelOptions( $state:Boolean ): void {
        pContainer.visible = $state;
    }

    private function addPixelOptions():void {
        pContainer = new VVBox( width-4, 30);
        pContainer.layout.orientation = LayoutOrientation.VERTICAL;
        pContainer.autoHeight = true;

        var ccb:ComponentCheckBox = new ComponentCheckBox("Remove Transparent Pixels", PictureImportProperties.hasTransparency, width * 1.4, toggleRemoveTransparent);
        pContainer.addElement(ccb);

        var values:Vector.<String> = new Vector.<String>();
        values.push("off white (0xf0)");
        values.push("White Smoke (0xf5)");
        values.push("pure white (0xff)");
        var data:Vector.<int> = new Vector.<int>();
        data.push(0xf0);
        data.push(0xf5);
        data.push(0xff);

        var ccbl:ComponentComboBoxWithLabel;
        ccbl = new ComponentComboBoxWithLabel( "White Tolerance"
                , whiteTolerance
                , values[0]
                , values
                , data
                , width - 10 );
        pContainer.addElement( ccbl );

        addElement(pContainer);

        function toggleRemoveTransparent( $me:UIMouseEvent ):void {
            PictureImportProperties.hasTransparency = ($me.target as CheckBox).selected;
        }

        function whiteTolerance( $le:ListEvent ):void {
            var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex );
            PictureImportProperties.transColor = li.data;
        }
    }

    private function pictureSize( $le:ListEvent ):void {
        var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex );
        PictureImportProperties.grain = li.data;
        trace("picture GRAIN: " + PictureImportProperties.grain);
        var size:int = GrainCursor.get_the_g0_size_for_grain( PictureImportProperties.grain );
        if ( null == PictureImportProperties.finalBitmapData )
                return;
        var correctSize:BitmapData = VVBox.drawScaled( PictureImportProperties.finalBitmapData, size, size, PictureImportProperties.hasTransparency );
        _container.backgroundTexture = VVBox.drawScaled( correctSize, _container.width, _container.height, PictureImportProperties.hasTransparency );
    }

    private var _loading:Boolean = false; // I get this message three times. Disable until complete
    private function urlChanged( $te:TextEvent ):void {
        if (  _loading )
            return;
        trace("WindowPictureImport.urlChanged $te: " + $te.target.text );
        PictureImportProperties.url = $te.target.text;
        var urlRequest:URLRequest = new URLRequest( PictureImportProperties.url );
        var urlLoader:URLLoader = new URLLoader();
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        _loading = true;
        urlLoader.addEventListener(Event.COMPLETE, urlLoader_complete);
        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_error);
        urlLoader.load(urlRequest);

        function urlLoader_complete($event:Event):void {
            urlLoader.removeEventListener(Event.COMPLETE, urlLoader_complete);
            urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoader_error);
            _loading = false;
            var loader:Loader = new Loader();
            // Event.INIT is needed to handle async aspect of loader
            loader.contentLoaderInfo.addEventListener(Event.INIT, function(e:Event):void {
                var bmpData:BitmapData = new BitmapData(e.target.width,e.target.height);
                bmpData.draw(loader,null,null);
                _container.addPicture( bmpData );
            });
            loader.addEventListener(IOErrorEvent.IO_ERROR, unknownType);
            loader.loadBytes($event.target.data);
        }

        function urlLoader_error(evt:IOErrorEvent):void {
            _loading = false;
            trace("file obviously not found");
        }

        function unknownType(evt:IOErrorEvent):void {
            _loading = false;
            (new Alert( "Unknown file format (try again sometimes helps)" )).display();
        }
    }

    private function createHandler( $me:UIMouseEvent ):void {
        if ( !PictureImportProperties.finalBitmapData ){
            (new Alert( LanguageManager.localizedStringGet( "No Image selected" ) )).display();
            return;
        }
        if ( "-1" == _ccbl.selectedItemValue ){
            (new Alert( LanguageManager.localizedStringGet( "No Size Selected" ) )).display();
            return;
        }
        var model:Object = GenerateCube.script( PictureImportProperties.grain, TypeInfo.AIR, true );
        model.name = StringUtils.getFileNameFromString(PictureImportProperties.url ); //"Picture Import";
        model.description = PictureImportProperties.url;
        var ii:InstanceInfo = new InstanceInfo();
        ii.modelGuid = Globals.getUID();
        addListeners();
        new ModelMakerGenerate(ii, model );

        function oxelBuildComplete($ode:OxelDataEvent):void {
            if ($ode.modelGuid == ii.modelGuid ) {
                trace( "WindowPictureImport.oxelBuildComplete");
                removeListeners();
                oxelCreated( $ode )
            }
        }

        function oxelBuildFailed($ode:OxelDataEvent):void {
            if ($ode.modelGuid == ii.modelGuid ) {
                removeListeners();
                (new Alert( LanguageManager.localizedStringGet( "picture_import_failed" ) )).display();
                ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            }
        }

        function addListeners():void {
            OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
            OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
            OxelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
//            OxelDataEvent.addListener( ModelBaseEvent.RESULT, oxelBuildComplete );
//            OxelDataEvent.addListener( ModelBaseEvent.ADDED, oxelBuildComplete );
        }

        function removeListeners():void {
//            OxelDataEvent.removeListener( ModelBaseEvent.ADDED, oxelBuildComplete );
//            OxelDataEvent.removeListener( ModelBaseEvent.RESULT, oxelBuildComplete );
            OxelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
            OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
            OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
        }

        function oxelCreated( $ode:OxelDataEvent ):void {
            $ode.oxelPersistence.loadFromByteArray();
            $ode.oxelPersistence.lightInfo.setIlluminationLevel(LightInfo.MAX);
            createModelFromBitmap( $ode.oxelPersistence );
        }
    }

    static public function createModelFromBitmap( $op:OxelPersistence ):void {
        //var grains:uint = Avatar.UNITS_PER_METER * PictureImportProperties.grain;
        var grains:uint = GrainCursor.get_the_g0_size_for_grain( PictureImportProperties.grain );
        var bitmapData:BitmapData = VVBox.drawScaled( PictureImportProperties.finalBitmapData, grains, grains, PictureImportProperties.hasTransparency );
        var oxel:Oxel = $op.oxel;
        var gct:GrainCursor = GrainCursorPool.poolGet( PictureImportProperties.grain );
        gct.grainX = 0;
        PictureImportProperties.traceProperties();
        for ( var iw:int = 0; iw < grains; iw++ ){
            for ( var ih:int = 0; ih < grains; ih++ ){
                gct.grainY = ih;
                gct.grainZ = iw;
                var pixelColor:uint = bitmapData.getPixel32(iw,grains-1-ih);
                var tOxel:Oxel;
                if ( PictureImportProperties.hasTransparency
                        && ColorUtils.extractRed( pixelColor ) >= PictureImportProperties.transColor
                        && ColorUtils.extractBlue( pixelColor ) >= PictureImportProperties.transColor
                        && ColorUtils.extractGreen( pixelColor ) >= PictureImportProperties.transColor )
                    tOxel = oxel.change( $op.guid, gct, TypeInfo.AIR, true);
                else if (  PictureImportProperties.replaceBlackWithIron && PictureImportProperties.hasTransparency
                        && ColorUtils.extractRed( pixelColor ) <= PictureImportProperties.blackColor
                        && ColorUtils.extractBlue( pixelColor ) <= PictureImportProperties.blackColor
                        && ColorUtils.extractGreen( pixelColor ) <= PictureImportProperties.blackColor )
                    tOxel = oxel.change( $op.guid, gct, TypeInfo.IRON, true);
                else {
                    tOxel = oxel.change($op.guid, gct, PictureImportProperties.pictureStyle, true);
                    tOxel.color = pixelColor;
                }
            }
        }
        // Since I tell the oxel.change to only change this oxel - the true.
        // I need to force it to build faces now.
        $op.oxel.facesBuild();
        $op.save();

        var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( $op.guid );
        if ( vm ){
            if ($op && $op.oxel && $op.oxel.gc.bound) {
                // Only do this for top level models.
                var radius:int = Math.max(GrainCursor.get_the_g0_edge_for_grain($op.oxel.gc.bound), 16)/2;
                // this gives me corner.
                var msCamPos:Vector3D = VoxelModel.controlledModel.cameraContainer.current.position;
                var adjCameraPos:Vector3D = VoxelModel.controlledModel.modelToWorld( msCamPos );

                var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.invModelMatrix.deltaTransformVector( new Vector3D( radius + 8, adjCameraPos.y-radius, -radius * 1.25 ) );
                var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet();
                diffPos = diffPos.add(lav);
                vm.instanceInfo.positionSet = diffPos;
                vm.instanceInfo.rotationSetComp( 0, 90, 0 );
                vm.modelInfo.hashTags = "#architecture#window#stained";

                OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE,  quadsComplete );
            }

            function quadsComplete( $ode:OxelDataEvent ):void {
                if (vm.modelInfo.guid == $ode.modelGuid) {
                    OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, quadsComplete);
                    var bmpd:BitmapData = Renderer.renderer.modelShot( vm );
                    vm.modelInfo.thumbnail = drawScaled(bmpd, 128, 128);
                    ModelInfoEvent.create(ModelBaseEvent.CHANGED, 0, vm.modelInfo.guid, vm.modelInfo);
                }
            }

            function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
                var m:Matrix = new Matrix();
                m.scale(destWidth/obj.width, destHeight/obj.height);
                var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
                bmpd.draw(obj, m);
                return bmpd;
            }
        }
        RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid );
    }

    override protected function onRemoved( event:UIOEvent ):void {
        super.onRemoved(event);
        PictureImportProperties.reset();
    }

}
}

