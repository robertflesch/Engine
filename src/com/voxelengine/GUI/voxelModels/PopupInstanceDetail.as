/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels {

import com.voxelengine.GUI.components.VVTextInput;
import com.voxelengine.GUI.panels.PanelBase;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Globals;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.InstanceInfoEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import org.flashapi.swing.plaf.spas.VVUI;

public class PopupInstanceDetail extends VVPopup {

    private static const instance_details:String = "instance_details";
    private static const instance_name:String = "instance_name";
    private static const instance_unnamed:String = "instance_unnamed";
    private static const instance_lighting:String = "instance_lighting";

    private static const relative_to_parent:String = "relative_to_parent";
    private static const world_space:String = "world_space";

	static private const WIDTH:int = 320;
	static private const PHOTO_SIZE:int = 128;
	// adding an alias for the function name to make code more readable
    private static var LM:Function = LanguageManager.localizedStringGet;

	private var _photoContainer:Container 		= new Container( width, 128 );
	private var _vm:VoxelModel = null;
	private var _baseLightLevel:int = 0;


	public function PopupInstanceDetail($vm:VoxelModel )
	{
		super( LM( instance_details ) );
		autoSize = false;
		autoHeight = true;
		width = WIDTH + 10;
		height = 600;
		padding = 0;
		paddingLeft = 5;

		_vm = $vm;
		var ii:InstanceInfo = _vm.instanceInfo; // short cut for brevity

		onCloseFunction = closeFunction;
		defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
		layout.orientation = LayoutOrientation.VERTICAL;
		shadow = true;

        addElement( new ComponentSpacer( WIDTH ) );
        addElement( new ComponentTextInput( LM( instance_name )
                , function ($e:TextEvent):void { ii.name = $e.target.text; setChanged(); }
                , ii.name ? ii.name : LM( instance_unnamed )
                , WIDTH ) );

        var panel:Container = new Container(width, 30);
        panel.addElement( new ComponentLabel( LM( LD.item_name ),  _vm.modelInfo.name ? _vm.modelInfo.name : LM( LD.item_no_name ), WIDTH/2 - 2 ) );
        panel.addElement( new ComponentLabel( LM( LD.owner ), 		_vm.modelInfo.owner ? _vm.modelInfo.owner : "No owner?", WIDTH/2 - 2 ) );
        addElement( panel );

        var desc:String = _vm.modelInfo.description ? _vm.modelInfo.description : LD.no_description;
		var lines:int = desc.length / 51 + 0.9;
		addElement( new ComponentMultiLineText( LM( LD.description ),  desc, WIDTH, Math.max( lines * 20, 32 ) ) );

        var photoOtherPanel:Container = new Container(width, PHOTO_SIZE);
        photoOtherPanel.layout.orientation = LayoutOrientation.HORIZONTAL;
        addElement( photoOtherPanel );

		_photoContainer.autoSize = false;
		_photoContainer.width = PHOTO_SIZE;
		_photoContainer.height = PHOTO_SIZE;
		_photoContainer.padding = 0;

        photoOtherPanel.addElement( _photoContainer );
        photoOtherPanel.addElement( new ComponentSpacer( 5, PHOTO_SIZE ) );
		addPhoto();

        var otherPanel:Container = new Container( WIDTH - PHOTO_SIZE - 6, PHOTO_SIZE + 12 );
        otherPanel.layout.orientation = LayoutOrientation.VERTICAL;
        photoOtherPanel.addElement( otherPanel );

        var lightPanel:VVBox = new VVBox( otherPanel.width, 86 );
        const GRAINS_PER_METER:int = 16;
		with ( lightPanel ){
			title = LM( instance_lighting );
			padding = 5;
            layout.orientation = LayoutOrientation.VERTICAL;

            var lb:Label = new Label( "0 is full bright, 255 is black", lightPanel.width );
            addElement( lb );

            var lightLevel:VVTextInput = new VVTextInput( String( _vm.instanceInfo.baseLightLevel ), 30 );
            eventCollector.addEvent( lightLevel, TextEvent.EDITED, function ($e:TextEvent):void { _baseLightLevel = Math.max( Math.min( uint( $e.target.text ), 255 ), 0 ) } );
            addElement( lightLevel );

            var applyLight:Button = new Button( "Apply Light", lightPanel.width - 12 );
            applyLight.addEventListener(UIMouseEvent.CLICK, changeBaseLightLevel );
            addElement( applyLight );


		}
        otherPanel.addElement( lightPanel );

        if ( $vm.modelInfo.oxelPersistence && $vm.modelInfo.oxelPersistence.oxelCount )
            otherPanel.addElement( new ComponentLabel( LM( LD.size_in_meters ), String( $vm.modelInfo.oxelPersistence.oxel.gc.size()/GRAINS_PER_METER ), otherPanel.width ) );
        else
            otherPanel.addElement( new ComponentLabel( LM( LD.size_in_meters ), "Unknown", otherPanel.width ) );


        if ( _vm.instanceInfo.controllingModel )
            addElement( new Label( LM( relative_to_parent ) ) );
		else
            addElement( new Label( LM( world_space ) ) );

		addElement( new ComponentVector3DToObject( setChanged, ii.setPositionInfo, LM( LD.position ), "X: ", "Y: ", "Z: ",  ii.positionGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setRotationInfo, LM( LD.rotation ), "X: ", "Y: ", "Z: ",  ii.rotationGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setScaleInfo,    LM( LD.scale ), "X: ", "Y: ", "Z: ",  ii.scale, WIDTH, updateScaleVal, 4 ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setCenterInfo,   LM( LD.center ), "X: ", "Y: ", "Z: ",  ii.centerNotScaled, WIDTH, updateVal ) );
		addElement( new ComponentSpacer( WIDTH ) );

		// TODO need to be able to handle an array of scripts.
		//addElement( new ComponentTextInput( "Script",  function ($e:TextEvent):void { ii.scriptName = $e.target.text; }, ii.scriptName, WIDTH ) );

		if ( Globals.isDebug ) {
			addElement( new ComponentLabel( LM( LD.item_guid ),  ii.modelGuid, WIDTH ) );
			addElement( new ComponentLabel( LM( LD.instance_guid ),  ii.instanceGuid, WIDTH ) );
		}
		if ( _vm.anim )
			// TODO add a drop down of available states
			addElement( new ComponentLabel( LM( LD.state ), _vm.anim ? _vm.anim.name : "", WIDTH ) );

		if ( ii.controllingModel ) {
            addElement(new ComponentLabel( LM( LD.parent_item_guid ), ii.controllingModel ? ii.controllingModel.modelInfo.guid : "", WIDTH));
            addElement(new ComponentLabel( LM( LD.parent_instance_guid ), ii.controllingModel ? ii.controllingModel.instanceInfo.instanceGuid : "", WIDTH));
        }

		if ( Globals.isDebug )	{
			var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
			oxelUtils.addEventListener(MouseEvent.CLICK, oxelUtilsHandler );
			addElement( oxelUtils );
            addElement( new ComponentSpacer( WIDTH, 5 ) );
        }

		display( 600, 20 );
	}

	static private function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
		var m:Matrix = new Matrix();
		m.scale(destWidth/obj.width, destHeight/obj.height);
		var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
		bmpd.draw(obj, m);
		return bmpd;
	}

	private function addPhoto():void {
		_photoContainer.removeElements();
		var bmd:BitmapData = null;
		if ( _vm.modelInfo.thumbnail )
			bmd = drawScaled( _vm.modelInfo.thumbnail, PHOTO_SIZE, PHOTO_SIZE );
		var pic:Image = new Image( new Bitmap( bmd ), PHOTO_SIZE, PHOTO_SIZE );
		_photoContainer.addElement( pic );
	}

	private function changeBaseLightLevel( $e:MouseEvent ):void  {
		if ( _vm.modelInfo.oxelPersistence && _vm.modelInfo.oxelPersistence.oxelCount ) {
			_vm.modelInfo.oxelPersistence.baseLightLevel( _baseLightLevel, true );
			_vm.instanceInfo.baseLightLevel = _baseLightLevel;
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
        if ( _vm.instanceInfo.controllingModel ) {
            _vm.instanceInfo.controllingModel.instanceInfo.changed = true;
            _vm.instanceInfo.controllingModel.modelInfo.changed = true;
        }
        _vm.instanceInfo.changed = true;
        _vm.modelInfo.changed = true;
    }


	private function setRecalcMatrix():void {
		// This changed is used in recalculating position matrix.
		// The actual instanceInfo data is not directly stored in DB.
		_vm.instanceInfo.recalcMatrix = true;
		if ( _vm.instanceInfo.controllingModel )
			_vm.instanceInfo.controllingModel.modelInfo.changed = true;
	}

	private function oxelUtilsHandler(event:MouseEvent):void  {
		if ( _vm )
			new WindowOxelUtils( _vm );
	}

	private function closeFunction():void {
		RegionEvent.create( ModelBaseEvent.CHANGED, 0, Region.currentRegion.guid );
		RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid );

        if ( _vm.modelInfo.changed ) {
            ModelInfoEvent.create( ModelBaseEvent.CHANGED, 0, _vm.modelInfo.guid, _vm.modelInfo );
            ModelInfoEvent.create( ModelBaseEvent.SAVE, 0,_vm.modelInfo.guid, _vm.modelInfo );
        }
        if ( _vm.instanceInfo.changed ) {
            InstanceInfoEvent.create( ModelBaseEvent.CHANGED, _vm.instanceInfo.instanceGuid, _vm.modelInfo.guid, _vm.instanceInfo );
            InstanceInfoEvent.create( ModelBaseEvent.SAVE, _vm.instanceInfo.instanceGuid,_vm.modelInfo.guid, _vm.instanceInfo );
        }

    }

}
}