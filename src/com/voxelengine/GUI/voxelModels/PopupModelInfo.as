/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.GUI.panels.*;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class PopupModelInfo extends VVPopup
{
    static private var _s_inExistance:int = 0;
    static public function get inExistance():int { return _s_inExistance; }
    static private var _s_currentInstance:PopupModelInfo = null;
    static public function get currentInstance():PopupModelInfo { return _s_currentInstance; }
    static private const WIDTH:int = 330;

    private var _photoContainer:Container 		= new Container( width, 128 );

    private var _mi:ModelInfo = null;

    private static const item_info:String = "item_info";
    private static const unnamed_item:String = "unnamed_item";
    private static const no_description:String = "no_description";
    private static const hashtags:String = "hashtags";
    private static const item_guid:String = "item_guid";
    private static const grain_size:String = "grain_size";
    private static const item_class:String = "item_class";
    private static const take_new_picture:String = "take_new_picture";
    private static var LM:Function = LanguageManager.localizedStringGet;

    public function PopupModelInfo($mi:ModelInfo )
    {
        super( LM( item_info ) );
        autoSize = false;
        autoHeight = true;
        width = WIDTH + 10;
        height = 600;
        padding = 0;
        paddingLeft = 5;

        _s_inExistance++;
        _s_currentInstance = this;

        _mi = $mi;

        ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoRetrieved );
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _mi.guid, null );

        onCloseFunction = closeFunction;
        defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
        layout.orientation = LayoutOrientation.VERTICAL;
        shadow = true;

        display( 600, 20 );
    }

    private function addMetadata():void {
        //addElement( new ComponentSpacer( WIDTH, 25 ) );

        addElement( new ComponentTextInput( LM( LD.item_name )
                , function ($e:TextEvent):void { _mi.name = $e.target.text; setChanged(); }
                , _mi.name ? _mi.name : unnamed_item
                , WIDTH ) );

        addElement( new ComponentTextArea( LM( LD.description ) + ' '
                , function ($e:TextEvent):void { _mi.description = $e.target.text; setChanged(); }
                , _mi.description ? _mi.description : LM( no_description )
                , WIDTH ) );

        addElement( new ComponentTextInput( LM( hashtags )
                , function ($e:TextEvent):void { _mi.hashTags = $e.target.text; setChanged(); }
                , _mi.hashTags
                , WIDTH ) );

    }

    private function addModelInfo():void {
        addElement( new ComponentSpacer( WIDTH, 10 ) );
        addPhoto();
        addMetadata();
        if ( Globals.isDebug )
            addElement( new ComponentLabel(  LM(item_guid),  _mi.guid, WIDTH ) );
        var panel:Container = new Container(width, 30);
        panel.addElement( new ComponentLabel( LM(grain_size),  LM( LD.grain) +': ' + String(_mi.grainSize) + " - " + Math.pow( 2, _mi.grainSize )/32 + ' ' +  LM(LD.meters), (WIDTH/2-2) ) );
        panel.addElement( new ComponentLabel( LM(item_class),  _mi.modelClass, (WIDTH/2-2) ) );
        addElement( panel );
        addAdvanced();
        addPermissions();
        // TODO need to be able to handle an array of scripts.
//            var scriptsPanel:PanelModelScripts = new PanelModelScripts( this, width, 20, 200);
    }

    private function modelInfoRetrieved( $mie:ModelInfoEvent ):void {
        if ( $mie.modelGuid == _mi.guid ) {
            ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, modelInfoRetrieved);
            _mi = $mie.modelInfo;
            addModelInfo();
        }
    }

    private function addPermissions():void {
        var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
        ebco.rootObject = _mi.permissions;
        ebco.title = ' ' + LM( LD.permissions ) + ' ';
        ebco.paddingTop = 7;
        ebco.width = WIDTH;
        addElement( new PanelPermissionModel( null, ebco ) );
    }

    private function addAdvanced():void {
        var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
        ebco.rootObject = _mi;
        ebco.title = ' ' + LM( LD.advanced ) + ' ';
        ebco.paddingTop = 7;
        ebco.width = WIDTH;
        addElement( new PanelAdvancedModel( null, ebco ) );
    }

    static private const PHOTO_WIDTH:int = 128;
    static private const PHOTO_HEIGHT:int = 128;
    static private const PHOTO_CAPTURE_WIDTH:int = 128;
    private function newPhoto( $me:UIMouseEvent ):void {
        var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _mi.guid );
        var bmpd:BitmapData = Renderer.renderer.modelShot( vm );
        _mi.thumbnail = drawScaledAndCropped( bmpd, PHOTO_CAPTURE_WIDTH, PHOTO_HEIGHT );
        addPhoto();
        ModelInfoEvent.create( ModelBaseEvent.CHANGED, 0, _mi.guid, _mi );
    }

    private function drawScaledAndCropped($bmp:BitmapData, destWidth:int, destHeight:int ):BitmapData {
        var m:Matrix = new Matrix();
        m.scale(destHeight/$bmp.height, destHeight/$bmp.height);
        var scale:Number = $bmp.height/destHeight;
        var finalWidth:int = $bmp.width/scale;
        var totalOffest:int = finalWidth - destWidth;
        m.translate( -totalOffest/2, 0 );
        var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
        bmpd.draw($bmp, m );
        return bmpd;
    }


    private function addPhoto():void {
        _photoContainer.layout.orientation = LayoutOrientation.VERTICAL;
        _photoContainer.layout.horizontalAlignment = HorizontalAlignment.CENTER;
        _photoContainer.autoSize = false;
        _photoContainer.width = WIDTH;
        _photoContainer.height = PHOTO_WIDTH + 35;
        _photoContainer.padding = 0;
        _photoContainer.name = "pc";
        addElement(_photoContainer);
        _photoContainer.removeElements();
        var bmd:BitmapData = null;
        if ( _mi.thumbnail )
            bmd = drawScaledAndCropped( _mi.thumbnail, PHOTO_WIDTH, PHOTO_HEIGHT );
        var pic:Image = new Image( new Bitmap( bmd ), PHOTO_WIDTH, PHOTO_HEIGHT );
        _photoContainer.addElement( pic );
        _photoContainer.addElement( new ComponentSpacer( WIDTH ) );
        var btn:Button = new Button( LM(take_new_picture), WIDTH , 24 );
        $evtColl.addEvent( btn, UIMouseEvent.CLICK, newPhoto );
        _photoContainer.addElement(btn);
        addElement( new ComponentSpacer( WIDTH, 10 ) );
    }

    private function setChanged():void {
		_mi.changed = true;
    }

    private function closeFunction():void {
        _s_inExistance--;
        _s_currentInstance = null;

        if ( _mi.changed ) {
            ModelInfoEvent.create( ModelBaseEvent.CHANGED, 0, _mi.guid, _mi );
            ModelInfoEvent.create( ModelBaseEvent.SAVE, 0, _mi.guid, _mi );
        }
    }
}
}