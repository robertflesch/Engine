/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{

import com.voxelengine.Log
import com.voxelengine.events.ModelLoadingEvent
import com.voxelengine.worldmodel.models.InstanceInfo
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateOxel;
import com.voxelengine.worldmodel.TypeInfo;

public class Axes extends VoxelModel
{
	static private var _model:VoxelModel = null;
	static private const AXES_MODEL_GUID:String = "Axes";
	static private const AXES_MODEL_GUID_X:String = "AxesX";
	static private const AXES_MODEL_GUID_Y:String = "AxesY";
	static private const AXES_MODEL_GUID_Z:String = "AxesZ";

	static public function createAxes():void {
		var ii:InstanceInfo = new InstanceInfo();
		var model:Object;
		model = GenerateCube.script( 0, TypeInfo.AIR );
		model.modelClass = "Axes";
		ii.modelGuid = AXES_MODEL_GUID;

		ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
		new ModelMakerGenerate( ii, model );

		function modelLoadComplete ( $mle:ModelLoadingEvent ):void {
			if ( $mle.data.modelGuid == AXES_MODEL_GUID ) {
				ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
				_model = $mle.vm;

				var iiR:InstanceInfo = new InstanceInfo();
				iiR.modelGuid = AXES_MODEL_GUID_X;
				iiR.controllingModel = _model;
				iiR.positionSetComp( 0, -1, -1 );
				new ModelMakerGenerate( iiR, GenerateCube.script( 0, TypeInfo.RED, true ) );

				var iiG:InstanceInfo = new InstanceInfo();
				iiG.modelGuid = AXES_MODEL_GUID_Y;
				iiG.controllingModel = _model;
				iiG.positionSetComp( -1, 0, -1 );
				new ModelMakerGenerate( iiG, GenerateCube.script( 0, TypeInfo.GREEN, true ) );

				var iiB:InstanceInfo = new InstanceInfo();
				iiB.modelGuid = AXES_MODEL_GUID_Z;
				iiB.controllingModel = _model;
				iiB.positionSetComp( -1, -1, 0 );
				new ModelMakerGenerate( iiB, GenerateCube.script( 0, TypeInfo.BLUE, true ) );
			}
		}
	}

	public function Axes( instanceInfo:InstanceInfo ) {
		super( instanceInfo );
		instanceInfo.dynamicObject = true;
	}

	override public function set dead(val:Boolean):void {
		Log.out( "Axes.dead - THIS MODEL IS IMMORTAL", Log.WARN );
	}
	
	static public function hide():void {
		if ( _model ) {
			VoxelModel.selectedModel.modelInfo.childRemove( _model.instanceInfo );
			_model.instanceInfo.visible = false;
		}
	}
	
	static public function show():void {
		if ( _model ) {
			var bound:int = VoxelModel.selectedModel.metadata.bound;
			var size:int = Math.max( bound - 3, 1 );
			var newScaleVal:uint = GrainCursor.two_to_the_g(bound)/size;
			//trace( " Axes.show size: " + size + "  newScaleVal: " + newScaleVal );
			_model.instanceInfo.setScaleInfo( { x: size, y : size, z: size } );

			var vmx:VoxelModel = _model.childFindModelGuid(AXES_MODEL_GUID_X);
			vmx.instanceInfo.setScaleInfo( { x: newScaleVal, y : 1, z: 1 } );

			var vmy:VoxelModel = _model.childFindModelGuid(AXES_MODEL_GUID_Y);
			vmy.instanceInfo.setScaleInfo( { x: 1, y : newScaleVal, z: 1 } );

			var vmz:VoxelModel = _model.childFindModelGuid(AXES_MODEL_GUID_Z);
			vmz.instanceInfo.setScaleInfo( { x: 1, y : 1, z: newScaleVal } );

			_model.instanceInfo.visible = true;
			VoxelModel.selectedModel.modelInfo.childAdd( _model );
		}
	}
}
}
