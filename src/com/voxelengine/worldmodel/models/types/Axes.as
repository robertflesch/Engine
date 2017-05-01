/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;

import flash.geom.Vector3D

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelLoadingEvent
import com.voxelengine.worldmodel.models.InstanceInfo
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateOxel;


/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class Axes extends VoxelModel 
{
	static private var _model:VoxelModel = null;
	static private var _loading:Boolean;
	static private const AXES_MODEL_GUID:String = "Axes";

	static public function createAxes():void {
		var ii:InstanceInfo = new InstanceInfo();
		var model:Object;
		model = GenerateOxel.cubeScript( 0, TypeInfo.RED );
		model.modelClass = "Axes";
		ii.modelGuid = AXES_MODEL_GUID;
		_loading = true;

		ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
		new ModelMakerGenerate( ii, model );

		function modelLoadComplete ( $mle:ModelLoadingEvent ):void {
			if ( $mle.data.modelGuid == AXES_MODEL_GUID ) {
				ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
				_model = $mle.vm;
				_loading = false;
			}
		}
	}

	public function Axes( instanceInfo:InstanceInfo ) {
		super( instanceInfo );
		instanceInfo.dynamicObject = true;
	}

	override public function set dead(val:Boolean):void {
		Log.out( "Axes.dead - THIS MODEL IS IMMORTAL");
	}
	
	static public function hide():void {
		if ( _model ) {
			//Log.out( "Axes.hide: " + VoxelModel.selectedModel , Log.WARN );
			VoxelModel.selectedModel.modelInfo.childRemove( _model.instanceInfo );
			_model.instanceInfo.visible = false
		}
	}
	
	static public function show():void {
		if ( _model ) {
			Log.out( "Axes.show: " + VoxelModel.selectedModel , Log.WARN );
			var bound:int = VoxelModel.selectedModel.metadata.bound;
			var scale:uint = GrainCursor.two_to_the_g(bound);
			_model.instanceInfo.setScaleInfo( { x: scale, y : scale, z: scale } );
			_model.instanceInfo.visible = true;
			VoxelModel.selectedModel.modelInfo.childAdd( _model );
		}
	}
	
	static public function scaleSet( $grain:int ):void {
		if ( _model ) {
			 var s:Number = Math.pow( 2, $grain)/32
			_model.instanceInfo.scaleSetComp( s, s, s )
		}
	}
	
	static public function positionSet( $pos:Vector3D ):void {
		if ( _model ) {
			_model.instanceInfo.positionSetComp( $pos.x, $pos.y, $pos.z )
		}
	}
	
	static public function rotationSet( $rot:Vector3D ):void {
		if ( _model ) {
			_model.instanceInfo.rotationSetComp( $rot.x, $rot.y, $rot.z )
		}
	}
	
	static public function centerSet( $rot:Vector3D ):void {
		if ( _model ) {
			_model.instanceInfo.centerSetComp( $rot.x, $rot.y, $rot.z )
		}
	}
	
	
	override public	function get selected():Boolean 					{ return false; }
	override public	function set selected(val:Boolean):void  			{ _selected = false; }
	
}
}
