/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels {
import com.voxelengine.events.InstanceInfoEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;

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
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;

import org.flashapi.swing.plaf.spas.VVUI;

public class WindowModelDetail extends VVPopup {
	static private const WIDTH:int = 330;
	static private const PHOTO_SIZE:int = 128;

	private var _photoContainer:Box 		= new Box( width, 128 );
	private var _vm:VoxelModel = null;
	private var _baseLightLevel:int = 0;

	public function WindowModelDetail( $vm:VoxelModel )
	{
		super( "Instance Details" );
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
		addElement( new ComponentTextInput( "Instance Name "
										  , function ($e:TextEvent):void { ii.name = $e.target.text; setChanged(); }
										  , ii.name ? ii.name : "Unnamed Instance"
										  , WIDTH ) );
		addElement( new ComponentLabel( "Model Name ",  _vm.metadata.name ? _vm.metadata.name : "Unnamed Model", WIDTH ) );
		addElement( new ComponentLabel( "Description",  _vm.metadata.description ? _vm.metadata.description : "No Description", WIDTH ) );

		_photoContainer.layout.orientation = LayoutOrientation.VERTICAL;
		_photoContainer.layout.horizontalAlignment = HorizontalAlignment.CENTER;
		_photoContainer.autoSize = false;
		_photoContainer.width = WIDTH;
		_photoContainer.height = PHOTO_SIZE + 10;
		_photoContainer.padding = 5;
		_photoContainer.name = "pc";
		_photoContainer.backgroundColor = VVUI.DEFAULT_COLOR;
		_photoContainer.title = "Photo";
		_photoContainer.borderStyle = BorderStyle.GROOVE;

		addElement(_photoContainer);
		addPhoto();

		addElement( new ComponentVector3DToObject( setChanged, ii.setPositionInfo, "Position", "X: ", "Y: ", "Z: ",  ii.positionGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setRotationInfo, "Rotation", "X: ", "Y: ", "Z: ",  ii.rotationGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setScaleInfo, "Scale", "X: ", "Y: ", "Z: ",  ii.scale, WIDTH, updateScaleVal, 4 ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setCenterInfo, "Center", "X: ", "Y: ", "Z: ",  ii.centerNotScaled, WIDTH, updateVal ) );
		addElement( new ComponentSpacer( WIDTH ) );

		var lc:Container = new Container( WIDTH, 30 );
		lc.padding = 0;
		lc.layout.orientation = LayoutOrientation.HORIZONTAL;

		_baseLightLevel = _vm.instanceInfo.baseLightLevel;
		lc.addElement( new ComponentLabelInput( "Light(0-255)"
								  , function ($e:TextEvent):void { _baseLightLevel = Math.max( Math.min( uint( $e.target.label ), 255 ), 0 );  }
								  , String( _baseLightLevel )
								  , WIDTH - 120 ) );

		var applyLight:Button = new Button( "Apply Light", 110 );
		applyLight.addEventListener(UIMouseEvent.CLICK, changeBaseLightLevel );
		lc.addElement( applyLight );
		addElement( lc );

		// TODO need to be able to handle an array of scripts.
		//addElement( new ComponentTextInput( "Script",  function ($e:TextEvent):void { ii.scriptName = $e.target.text; }, ii.scriptName, WIDTH ) );
		const GRAINS_PER_METER:int = 16;
		if ( $vm.modelInfo.oxelPersistence && $vm.modelInfo.oxelPersistence.oxelCount )
			addElement( new ComponentLabel( "Size in Meters", String( $vm.modelInfo.oxelPersistence.oxel.gc.size()/GRAINS_PER_METER ), WIDTH ) );
		else
			addElement( new ComponentLabel( "Size in Meters", "Unknown", WIDTH ) );

		if ( Globals.isDebug ) {
			addElement( new ComponentLabel( "Model GUID",  ii.modelGuid, WIDTH ) );
			addElement( new ComponentLabel( "Instance GUID",  ii.instanceGuid, WIDTH ) );
		}
		if ( _vm.anim )
			// TODO add a drop down of available states
			addElement( new ComponentLabel( "State", _vm.anim ? _vm.anim.name : "", WIDTH ) );

		if ( ii.controllingModel )
			addElement( new ComponentLabel( "Parent GUID",  ii.controllingModel ? ii.controllingModel.instanceInfo.instanceGuid : "", WIDTH ) );

		if ( Globals.isDebug )	{
			var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
			oxelUtils.addEventListener(MouseEvent.CLICK, oxelUtilsHandler );
			addElement( oxelUtils );
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
		if ( _vm.metadata.thumbnail )
			bmd = drawScaled( _vm.metadata.thumbnail, PHOTO_SIZE, PHOTO_SIZE );
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
        _vm.instanceInfo.changed = true
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

	    if ( _vm.metadata.changed ) {
            ModelMetadataEvent.create( ModelBaseEvent.CHANGED, 0, _vm.modelInfo.guid, _vm.metadata );
            ModelMetadataEvent.create( ModelBaseEvent.SAVE, 0, _vm.modelInfo.guid, _vm.metadata );
        }
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