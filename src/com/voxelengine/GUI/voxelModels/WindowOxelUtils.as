/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;


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

		var lod:Button = new Button( "GenerateLOD" );
		lod.addEventListener(UIMouseEvent.CLICK, generateLODHandler );
		lod.width = 150;
		addElement( lod );

		var rotate:Button = new Button( "Rotate Oxel" );
		rotate.addEventListener(UIMouseEvent.CLICK, rotateHandler );
		rotate.width = 150;
		addElement( rotate );
		
		//var center:Button = new Button( "Center" );
		//center.addEventListener(UIMouseEvent.CLICK, centerHandler );
		//center.width = 150;
		//addElement( center );
		
		var mergeSame:Button = new Button( "Merge Same Oxel" );
		mergeSame.addEventListener(UIMouseEvent.CLICK, mergeSameHandler );
		mergeSame.width = 150;
		addElement( mergeSame );
		
		var mergeAir:Button = new Button( "Merge Air Oxels" );
		mergeAir.addEventListener(UIMouseEvent.CLICK, mergeAirHandler );
		mergeAir.width = 150;
		addElement( mergeAir );
		
		//var breakDownB:Button = new Button( "Breakdown" );
		//breakDownB.addEventListener(UIMouseEvent.CLICK, breakdownHandler );
		//breakDownB.width = 150;
		//addElement( breakDownB );
//
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
		
		var rebuildFacesInfo:Button = new Button( "Rebuild Model" );
		rebuildFacesInfo.addEventListener(UIMouseEvent.CLICK, rebuildModelHandler );
		rebuildFacesInfo.width = 150;
		addElement( rebuildFacesInfo );

		var rebuildLightingInfo:Button = new Button( "Rebuild Lighting" );
		rebuildLightingInfo.addEventListener(UIMouseEvent.CLICK, rebuildLightingHandler );
		rebuildLightingInfo.width = 150;
		addElement( rebuildLightingInfo );

		var rebuildWaterInfo:Button = new Button( "Rebuild Water" );
		rebuildWaterInfo.addEventListener(UIMouseEvent.CLICK, rebuildWaterHandler );
		rebuildWaterInfo.width = 150;
		addElement( rebuildWaterInfo );
		
		var rebuildGrassInfo:Button = new Button( "Rebuild Grass" );
		rebuildGrassInfo.addEventListener(UIMouseEvent.CLICK, rebuildGrassHandler );
		rebuildGrassInfo.width = 150;
		addElement( rebuildGrassInfo );
		
		var resetOxelScaling:Button = new Button( "Rebuild Scaling" );
		resetOxelScaling.addEventListener(UIMouseEvent.CLICK, resetOxelScalingHandler );
		resetOxelScaling.width = 150;
		addElement( resetOxelScaling );
		
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

	private function generateLODHandler(event:UIMouseEvent):void {
		//_vm.modelInfo.oxelPersistence.generateLOD();
		_vm.generateAllLODs();
	}

	private function rotateHandler(event:UIMouseEvent):void {
		_vm.modelInfo.oxelPersistence.oxel.rotateCCW();
	}

	private function centerHandler(event:UIMouseEvent):void {
		_vm.modelInfo.oxelPersistence.oxel.centerOxel();
	}
	
	private function breakdownHandler(event:UIMouseEvent):void {
		_vm.breakdown();
	}
	
	private function changeTypeHandler(event:UIMouseEvent):void {
		new WindowChangeType( _vm );
	}

	private function mergeSameHandler(event:UIMouseEvent):void {
		_vm.modelInfo.oxelPersistence.oxel.mergeAndRebuild();
		_vm.modelInfo.oxelPersistence.changed = true
	}
	
	private function mergeAirHandler(event:UIMouseEvent):void {
		_vm.modelInfo.oxelPersistence.oxel.mergeAIRAndRebuild();
		_vm.modelInfo.oxelPersistence.changed = true
	}
	
	private function decreaseGrainHandler(event:UIMouseEvent):void {
		_vm.changeGrainSize( -1 )
	}
	
	private function increaseGrainHandler(event:UIMouseEvent):void {
		_vm.changeGrainSize( 1 )
	}

	private function rebuildLightingHandler(event:UIMouseEvent):void {
		_vm.rebuildLightingHandler();
	}

	private function rebuildWaterHandler(event:UIMouseEvent):void {
		VoxelModel.visitor( VisitorFunctions.rebuildWater, "Oxel.rebuildWater" );
	}
	
	private function rebuildGrassHandler(event:UIMouseEvent):void {
		VoxelModel.visitor( VisitorFunctions.rebuildGrass, "Oxel.rebuildGrass" );
	}
	
	private function rebuildModelHandler(event:UIMouseEvent):void {
		//_vm.modelInfo.oxelPersistence.visitor( Oxel.rebuild, "Oxel.rebuild" );
//		var buildFaces:Boolean = true;
//		var forceFaces:Boolean = true;
//		var forceQuads:Boolean = true;
		_vm.modelInfo.oxelPersistence.forceFaces = true;
		_vm.modelInfo.oxelPersistence.forceQuads = true;
		_vm.modelInfo.oxelPersistence.changed = true;
		//_vm.modelInfo.oxelPersistence.oxel.chunkGet().faceAndQuadsBuild( buildFaces, forceFaces, forceQuads );
	}
	
	private function resetOxelScalingHandler(event:UIMouseEvent):void {
		VoxelModel.visitor( VisitorFunctions.resetScaling, "Oxel.resetScaling" );
	}
	
}	
}