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


public class WindowModelDetail extends VVPopup
{
	static private var _s_inExistance:int = 0;
	static private var _s_currentInstance:WindowModelDetail = null;

	private var _panelAdvanced:Panel;
	private var _photoContainer:Container 		= new Container( width, 128 );

	private var _vm:VoxelModel = null;

	private static const BORDER_WIDTH:int = 4;
	private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
	private static const BORDER_WIDTH_3:int = BORDER_WIDTH * 3;
	private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
	private static const PANEL_HEIGHT:int = 115;

	static private const WIDTH:int = 330;
	static public function get inExistance():int { return _s_inExistance; }
	static public function get currentInstance():WindowModelDetail { return _s_currentInstance; }

	public function WindowModelDetail( $vm:VoxelModel )
	{
		super( "Model Details" );
		autoSize = false;
		autoHeight = true;
		width = WIDTH + 10;
		height = 600;
		padding = 0;
		paddingLeft = 5;

		_s_inExistance++;
		_s_currentInstance = this;

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
		// TODO: this should be read only
//		addElement( new ComponentTextInput( "Model Name "
//				, function ($e:TextEvent):void { _vm.metadata.name = $e.target.text; setChanged(); }
//				, _vm.metadata.name ? _vm.metadata.name : "Unnamed Model"
//				, WIDTH ) );
		addElement( new ComponentLabel( "Model Name ",  _vm.metadata.name ? _vm.metadata.name : "Unnamed Model", WIDTH ) );


		_photoContainer.layout.orientation = LayoutOrientation.VERTICAL;
		_photoContainer.layout.horizontalAlignment = HorizontalAlignment.CENTER;
		_photoContainer.autoSize = false;
		_photoContainer.width = WIDTH;
		_photoContainer.height = PHOTO_WIDTH + 30;
		_photoContainer.padding = 0;
		_photoContainer.name = "pc";
		addElement(_photoContainer);
		addPhoto()

//		addElement( new ComponentTextArea( "Description "
//										 , function ($e:TextEvent):void { _vm.metadata.description = $e.target.text; setChanged(); }
//										 , _vm.metadata.description ? _vm.metadata.description : "No Description"
//										 , WIDTH ) );
		addElement( new ComponentLabel( "Description",  _vm.metadata.description ? _vm.metadata.description : "No Description", WIDTH ) );

		addElement( new ComponentVector3DToObject( setChanged, ii.setPositionInfo, "Position", "X: ", "Y: ", "Z: ",  ii.positionGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setRotationInfo, "Rotation", "X: ", "Y: ", "Z: ",  ii.rotationGet, WIDTH, updateVal ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setScaleInfo, "Scale", "X: ", "Y: ", "Z: ",  ii.scale, WIDTH, updateScaleVal, 4 ) );
		addElement( new ComponentVector3DToObject( setChanged, ii.setCenterInfo, "Center", "X: ", "Y: ", "Z: ",  ii.center, WIDTH, updateVal ) );
//			addElement( new ComponentVector3DSideLabel( setChanged, "Center", "X: ", "Y: ", "Z: ",  ii.center, WIDTH, updateVal ) );
		addElement( new ComponentSpacer( WIDTH ) );

		var lc:Container = new Container( WIDTH, 30 );
		lc.padding = 0;
		lc.layout.orientation = LayoutOrientation.HORIZONTAL;

		lc.addElement( new ComponentLabelInput( "Light(0-255)"
								  , function ($e:TextEvent):void { _vm.modelInfo.baseLightLevel = Math.max( Math.min( uint( $e.target.label ), 255 ), 0 );  }
								  , String( _vm.modelInfo.baseLightLevel )
								  , WIDTH - 120 ) );

		var applyLight:Button = new Button( "Apply Light", 110 );
		applyLight.addEventListener(UIMouseEvent.CLICK, changeBaseLightLevel );
		lc.addElement( applyLight );
		addElement( lc );

		// TODO need to be able to handle an array of scipts.
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

		addPermissions()
//
		if ( Globals.isDebug )	{
			var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
			oxelUtils.addEventListener(UIMouseEvent.CLICK, oxelUtilsHandler );
			//oxelUtils.width = pbWidth - 2 * pbPadding;
			addElement( oxelUtils );
		}

		display( 600, 20 );
	}

	private function addPermissions():void {
		var ebco:ExpandableBoxConfigObject = new ExpandableBoxConfigObject();
		ebco.rootObject = _vm.metadata.permissions;
		ebco.title = " permissions ";
		ebco.paddingTop = 7;
		ebco.width = WIDTH;
		addElement( new PanelPermissionModel( null, ebco ) );
	}

	static private const PHOTO_WIDTH:int = 128;
	static private const PHOTO_CAPTURE_WIDTH:int = 128;
	private function newPhoto( $me:UIMouseEvent ):void {
		var bmpd:BitmapData = Renderer.renderer.modelShot();
		_vm.metadata.thumbnail = drawScaled( bmpd, PHOTO_CAPTURE_WIDTH, PHOTO_CAPTURE_WIDTH );
		addPhoto();
		ModelMetadataEvent.create( ModelBaseEvent.CHANGED, 0, _vm.metadata.guid, _vm.metadata );
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
		if ( _vm.metadata.thumbnail )
			bmd = drawScaled( _vm.metadata.thumbnail, PHOTO_WIDTH, PHOTO_WIDTH );
		var pic:Image = new Image( new Bitmap( bmd ), PHOTO_WIDTH, PHOTO_WIDTH );
		_photoContainer.addElement( pic );

		var btn:Button = new Button( "Take New Picture", WIDTH , 20 );
		$evtColl.addEvent( btn, UIMouseEvent.CLICK, newPhoto );
		_photoContainer.addElement(btn);
	}

	private function changeBaseLightLevel( $e:UIMouseEvent ):void  {
		if ( _vm.modelInfo.oxelPersistence && _vm.modelInfo.oxelPersistence.oxelCount ) {
			//var oxel:Oxel = _vm.modelInfo.oxelPersistence.oxel;
			_vm.applyBaseLightLevel();
			_vm.modelInfo.oxelPersistence.changed = true;
			_vm.modelInfo.save();
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
		_vm.instanceInfo.changed = true;
		if ( _vm.instanceInfo.controllingModel )
			_vm.instanceInfo.controllingModel.modelInfo.changed = true;
	}

	private function oxelUtilsHandler(event:UIMouseEvent):void  {

		if ( _vm )
			new WindowOxelUtils( _vm );
	}

	private function closeFunction():void
	{
		_s_inExistance--;
		_s_currentInstance = null;

		RegionEvent.create( ModelBaseEvent.CHANGED, 0, Region.currentRegion.guid );
		RegionEvent.create( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid );
	}


	private function changeStateHandler(event:TextEvent):void {
		var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _vm.instanceInfo.instanceGuid )
		var state:String = event.target.text;
		vm.stateLock( false );
		vm.stateSet( state );
		vm.stateLock( true );
	}

}
}