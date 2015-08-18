/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.GUI.VVPopup;
import flash.utils.ByteArray;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;


import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class WindowOxelUtils extends VVPopup
{
	private var _vm:VoxelModel = null;
	
	public function WindowOxelUtils ( vm:VoxelModel )
	{
		super( "Oxel Utils" );
		_vm = vm;
		autoSize = true;
		
		layout.orientation = LayoutOrientation.VERTICAL;	
		
		var changeType:Button = new Button( "Change Type..." );
		changeType.addEventListener(UIMouseEvent.CLICK, changeTypeHandler );
		changeType.width = 150;
		addElement( changeType );
		
		var rotate:Button = new Button( "Rotate Oxel" );
		rotate.addEventListener(UIMouseEvent.CLICK, rotateHandler );
		rotate.width = 150;
		addElement( rotate );
		
		var center:Button = new Button( "Center" );
		center.addEventListener(UIMouseEvent.CLICK, centerHandler );
		center.width = 150;
		addElement( center );
		
		var mergeSame:Button = new Button( "Merge Same Oxel" );
		mergeSame.addEventListener(UIMouseEvent.CLICK, mergeSameHandler );
		mergeSame.width = 150;
		addElement( mergeSame );
		
		var mergeAir:Button = new Button( "Merge Air" );
		mergeAir.addEventListener(UIMouseEvent.CLICK, mergeAirHandler );
		mergeAir.width = 150;
		addElement( mergeAir );
		
		var breakDownB:Button = new Button( "Breakdown" );
		breakDownB.addEventListener(UIMouseEvent.CLICK, breakdownHandler );
		breakDownB.width = 150;
		addElement( breakDownB );

		var validate:Button = new Button( "Validate" );
		validate.addEventListener(UIMouseEvent.CLICK, validateHandler );
		validate.width = 150;
		addElement( validate );
		
		var decreaseGrain:Button = new Button( "Decrease Grain" );
		decreaseGrain.addEventListener(UIMouseEvent.CLICK, decreaseGrainHandler );
		decreaseGrain.width = 150;
		addElement( decreaseGrain );
		
		var increaseGrain:Button = new Button( "Increase Grain" );
		increaseGrain.addEventListener(UIMouseEvent.CLICK, increaseGrainHandler );
		increaseGrain.width = 150;
		addElement( increaseGrain );
		
		var statsB:Button = new Button( "Print Stats" );
		statsB.addEventListener(UIMouseEvent.CLICK, statsHandler );
		statsB.width = 150;
		addElement( statsB );
		
		var baseLightLevelB:Button = new Button( "Set Base Light Level..." );
		baseLightLevelB.addEventListener(UIMouseEvent.CLICK, baseLightLevelHandler );
		baseLightLevelB.width = 150;
		addElement( baseLightLevelB );

		var resetFlowInfo:Button = new Button( "Reset FlowInfo..." );
		resetFlowInfo.addEventListener(UIMouseEvent.CLICK, resetFlowInfoHandler );
		resetFlowInfo.width = 150;
		addElement( resetFlowInfo );
		
		//var fullBrightB:Button = new Button( "Full Bright" );
		//fullBrightB.addEventListener(UIMouseEvent.CLICK, fullBrightHandler );
		//fullBrightB.width = 150;
		//addElement( fullBrightB );

		
		//var saveModelDataB:Button = new Button( "Save Model Data" );
		//saveModelDataB.addEventListener(UIMouseEvent.CLICK, saveModelDataHandler );
		//saveModelDataB.width = 150;
		//addElement( saveModelDataB );
		
		display( 400, 20 );
	}

	
	private function statsHandler(event:UIMouseEvent):void 
	{
		throw new Error( "ParticleLoadingTask - NEED TO REWRITE" );
		//var ba:ByteArray = Globals.findIVM( _vm.modelInfo.biomes.layers[0].data );
		//// this positions the ba pointer to the oxel data, which is what the statisics needs
		//var versionInfo:Object = ModelLoader.modelMetaInfoRead( ba );
		//if ( 0 != versionInfo.manifestVersion ) {
			//// how many bytes is the modelInfo
			//var strLen:int = ba.readInt();
			//// read off that many bytes
			//var modelInfoJson:String = ba.readUTFBytes( strLen );
		//}
		//
		//_vm.statisics.gather( Globals.VERSION, ba, _vm.oxel.gc.grain );
		//_vm.statisics.statsPrint();
	}
	
	
	private function resetFlowInfoHandler(event:UIMouseEvent):void {
		_vm.modelInfo.data.oxel.resetFlowInfo();
	}
	
	private function baseLightLevelHandler(event:UIMouseEvent):void {
		new WindowChangeBaseLightLevel( _vm );
	}
		

	import flash.utils.Timer;
	import flash.events.TimerEvent;
	private var _reloadTimer:Timer;
	private var startingVal:uint = 0x33;
	private function fullBrightHandler(event:UIMouseEvent):void {
	
		_reloadTimer = new Timer( 250 );
		_reloadTimer.addEventListener(TimerEvent.TIMER, onRepeat);
		_reloadTimer.start();
	}

	protected function onRepeat(event:TimerEvent):void
	{
		Log.out( "WindowOxelUtils.onRepeat - startingVal: " + startingVal );
		_vm.modelInfo.data.oxel.fullBright( startingVal );
		
		if ( 0xff == startingVal ) {
			_reloadTimer.stop();
		}
		
		startingVal++;
	}
	
	//private function saveModelDataHandler(event:UIMouseEvent):void 
	//{
		//Globals.g_gui.saveModelIVM(null);
	//}

	private function rotateHandler(event:UIMouseEvent):void 
	{
		_vm.modelInfo.data.oxel.rotateCCW();
	}

	private function centerHandler(event:UIMouseEvent):void 
	{
		_vm.modelInfo.data.oxel.centerOxel();
	}
	
	private function breakdownHandler(event:UIMouseEvent):void 
	{
		_vm.breakdown();
	}
	
	private function changeTypeHandler(event:UIMouseEvent):void 
	{
		new WindowChangeType( _vm );
	}

	private function validateHandler(event:UIMouseEvent):void 
	{
		_vm.validate();
		_vm.modelInfo.data.oxel.rebuildAll();
	}
	
	private function mergeSameHandler(event:UIMouseEvent):void 
	{
		_vm.modelInfo.data.oxel.mergeAndRebuild();
	}
	
	private function mergeAirHandler(event:UIMouseEvent):void 
	{
		_vm.modelInfo.data.oxel.mergeAirAndRebuild();
	}
	
	
	private function decreaseGrainHandler(event:UIMouseEvent):void 
	{
		_vm.changeGrainSize( -1 );
	}
	
	private function increaseGrainHandler(event:UIMouseEvent):void 
	{
		_vm.changeGrainSize( 1 );
	}
}	
}