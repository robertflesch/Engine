/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Matrix;

import org.flashapi.collector.EventCollector;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.GUI.panels.*;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;


public class PopupMetadataAndModelInfo extends VVPopup
{
    static private var _s_inExistance:int = 0;
    static public function get inExistance():int { return _s_inExistance; }
    static private var _s_currentInstance:PopupMetadataAndModelInfo = null;
    static public function get currentInstance():PopupMetadataAndModelInfo { return _s_currentInstance; }
    static private const WIDTH:int = 330;

    private var _panelAdvanced:Panel;
    private var _photoContainer:Container 		= new Container( width, 128 );

    private var _mmd:ModelMetadata = null;
    private var _mi:ModelInfo = null;

    public function PopupMetadataAndModelInfo( $mmd:ModelMetadata )
    {
        super( "Model Metadata and Info" );
        autoSize = false;
        autoHeight = true;
        width = WIDTH + 10;
        height = 600;
        padding = 0;
        paddingLeft = 5;

        _s_inExistance++;
        _s_currentInstance = this;

        _mmd = $mmd;
        addMetadata();
        ModelInfoEvent.addListener( ModelBaseEvent.ADDED, modelInfoRetreived );
        ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoRetreived );
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _mmd.guid, null );

        onCloseFunction = closeFunction;
        defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
        layout.orientation = LayoutOrientation.VERTICAL;
        shadow = true;

        display( 600, 20 );
    }

    private function addMetadata():void {
        addElement( new ComponentSpacer( WIDTH ) );
        _photoContainer.layout.orientation = LayoutOrientation.VERTICAL;
        _photoContainer.layout.horizontalAlignment = HorizontalAlignment.CENTER;
        _photoContainer.autoSize = false;
        _photoContainer.width = WIDTH;
        _photoContainer.height = PHOTO_WIDTH + 35;
        _photoContainer.padding = 0;
        _photoContainer.name = "pc";
        addElement(_photoContainer);
        addPhoto();
        addElement( new ComponentSpacer( WIDTH ) );
        addElement( new ComponentTextInput( "Model Name "
                , function ($e:TextEvent):void { _mmd.name = $e.target.text; setChanged(); }
                , _mmd.name ? _mmd.name : "Unnamed Model"
                , WIDTH ) );

        addElement( new ComponentTextArea( "Description "
                , function ($e:TextEvent):void { _mmd.description = $e.target.text; setChanged(); }
                , _mmd.description ? _mmd.description : "No Description"
                , WIDTH ) );

        addElement( new ComponentLabel( "Version",  String(_mmd.version), WIDTH ) );
        addElement( new ComponentLabel( "Animation class",  String(_mmd.animationClass), WIDTH ) );
        addElement( new ComponentLabel( "Child of",  String(_mmd.childOf), WIDTH ) );
        if ( _mmd.childOf ){
            if ( null == _mmd.modelPosition )
                _mmd.modelPosition = {x:0,y:0,z:0};
            if ( null == _mmd.modelScaling )
                _mmd.modelScaling = {x:1,y:1,z:1};
            addElement( new ComponentVector3DToObject( setChanged, _mmd.modelPositionInfo, "Position Relative To Parent", "X: ", "Y: ", "Z: ",  _mmd.modelPositionVec3D(), WIDTH, updateVal ) );
            addElement( new ComponentVector3DToObject( setChanged, _mmd.modelScalingInfo, "Model Scaling", "X: ", "Y: ", "Z: ",  _mmd.modelScalingVec3D(), WIDTH, updateVal ) );
        }
        addElement( new ComponentLabel( "Owner",  String(_mmd.owner), WIDTH ) );
        addElement( new ComponentTextInput( "HashTags"
                , function ($e:TextEvent):void { _mmd.hashTags = $e.target.text; setChanged(); }
                , _mmd.hashTags
                , WIDTH ) );
        addElement( new ComponentLabel( "Created Date",  String(_mmd.createdDate), WIDTH ) );
        addElement( new ComponentLabel( "Creator",  String(_mmd.creator), WIDTH ) );

        addPermissions();
    }

    private function addModelInfo():void {
        addElement( new ComponentLabel( "Model GUID",  _mi.guid, WIDTH ) );
        addElement( new ComponentLabel( "Model Class",  _mi.modelClass, WIDTH ) );
//        addElement( new ComponentLabel( "Created Date",  _mi.createdDate, WIDTH ) );
//        addElement( new ComponentLabel( "Creator",  _mi.creator, WIDTH ) );

//        if (  _mi.oxelPersistence ) {
//            var lc:Container = new Container(WIDTH, 30);
//            lc.padding = 0;
//            lc.layout.orientation = LayoutOrientation.HORIZONTAL;
//
//            lc.addElement(new ComponentLabelInput("Light(0-255)"
//                    , function ($e:TextEvent):void {
//                        _mi.oxelPersistence.baseLightLevel = Math.max(Math.min(uint($e.target.label), 255), 0);
//                    }
//                    , String(_mi.oxelPersistence.baseLightLevel)
//                    , WIDTH - 120));
//
//            addElement(lc);
//        }

        // TODO need to be able to handle an array of scripts.
//            var scriptsPanel:PanelModelScripts = new PanelModelScripts( this, width, 20, 200);

        const GRAINS_PER_METER:int = 16;
        addElement( new ComponentLabel( "Grain Size",  String(_mi.grainSize), WIDTH ) );
//        if ( _mi.oxelPersistence && _mi.oxelPersistence.bound )
//            addElement( new ComponentLabel( "Size in Meters", String( (_mi.oxelPersistence.bound ^ 2)/GRAINS_PER_METER ), WIDTH ) );
    }

    private function modelInfoRetreived( $mie:ModelInfoEvent ):void {
        if ( $mie.modelGuid == _mmd.guid ) {
            ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, modelInfoRetreived);
            ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, modelInfoRetreived);
            _mi = $mie.vmi;
            addModelInfo();
        }
    }

    private function addPermissions():void {
        var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
        ebco.rootObject = _mmd.permissions;
        ebco.title = " permissions ";
        ebco.paddingTop = 7;
        ebco.width = WIDTH;
        addElement( new PanelPermissionModel( null, ebco ) );
    }

    static private const PHOTO_WIDTH:int = 128;
    static private const PHOTO_CAPTURE_WIDTH:int = 128;
    private function newPhoto( $me:UIMouseEvent ):void {
        var bmpd:BitmapData = Renderer.renderer.modelShot();
        _mmd.thumbnail = drawScaled( bmpd, PHOTO_CAPTURE_WIDTH, PHOTO_CAPTURE_WIDTH );
        addPhoto();
        ModelMetadataEvent.create( ModelBaseEvent.CHANGED, 0, _mmd.guid, _mmd );
    }

    private function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
        var m:Matrix = new Matrix();
        m.scale(destWidth/obj.width, destHeight/obj.height);
        var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
        bmpd.draw(obj, m);
        return bmpd;
    }
    private function addPhoto():void {
        _photoContainer.removeElements();
        var bmd:BitmapData = null;
        if ( _mmd.thumbnail )
            bmd = drawScaled( _mmd.thumbnail, PHOTO_WIDTH, PHOTO_WIDTH );
        var pic:Image = new Image( new Bitmap( bmd ), PHOTO_WIDTH, PHOTO_WIDTH );
        _photoContainer.addElement( pic );
        _photoContainer.addElement( new ComponentSpacer( WIDTH ) );
        var btn:Button = new Button( "Take New Picture", WIDTH , 24 );
        $evtColl.addEvent( btn, UIMouseEvent.CLICK, newPhoto );
        _photoContainer.addElement(btn);
    }

    private function changeBaseLightLevel( $e:UIMouseEvent ):void  {
        if ( _mi.oxelPersistence && _mi.oxelPersistence.oxelCount ) {
            var oxel:Oxel = _mi.oxelPersistence.oxel;
//            _vm.applyBaseLightLevel();
            _mi.oxelPersistence.changed = true;
            _mi.save();
        }
    }

    private function updateScaleVal( $e:SpinButtonEvent ):Number {
        var ival:Number = Number( $e.target.data.text );
        if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival = ival/2;
        else 											ival = ival*2;
        $e.target.data.text = ival.toString();
        setChanged();
        return ival;
    }

    private function updateVal( $e:SpinButtonEvent ):int {
        var ival:int = int( $e.target.data.text );
        if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
        else 											ival++;
        setChanged();
        $e.target.data.text = ival.toString();
        return ival;
    }

    private function setChanged():void {
		_mmd.changed = true;
		_mi.changed = true;
    }

    private function closeFunction():void
    {
        _s_inExistance--;
        _s_currentInstance = null;

        if ( _mmd.changed ) {
            ModelMetadataEvent.create( ModelBaseEvent.CHANGED, 0, _mi.guid, _mmd );
            ModelMetadataEvent.create( ModelBaseEvent.SAVE, 0, _mi.guid, _mmd );
        }
        if ( _mi.changed ) {
            ModelInfoEvent.create( ModelBaseEvent.CHANGED, 0, _mi.guid, _mi );
            ModelInfoEvent.create( ModelBaseEvent.SAVE, 0, _mi.guid, _mi );
        }
    }
}
}