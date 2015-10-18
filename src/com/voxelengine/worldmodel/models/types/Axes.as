/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelLoadingEvent
import com.voxelengine.worldmodel.models.InstanceInfo
import com.voxelengine.worldmodel.models.ModelMetadata
import com.voxelengine.worldmodel.models.ModelInfo
import com.voxelengine.worldmodel.models.makers.ModelMakerBase
import com.voxelengine.worldmodel.models.types.VoxelModel
//import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D

/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class Axes extends VoxelModel 
{
	static private var _model:VoxelModel
	static private var _loading:Boolean
	static private const AXES_MODEL_GUID:String = "A74EDB66-074E-EB7E-739A-B307D5AA89D9"
	static public function display():void {
		if ( null == _model && false == _loading ) {
			_loading = true
			var ii:InstanceInfo = new InstanceInfo()
			ii.modelGuid = AXES_MODEL_GUID
			ii.dynamicObject = true
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, axesLoaded )

			ModelMakerBase.load( ii, true, false )
		}
		
		function axesLoaded( $mle:ModelLoadingEvent):void {
			if ( $mle.modelGuid == AXES_MODEL_GUID ) {
				ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, axesLoaded )
				_model = $mle.vm
				_loading = false
			}
		}
	}

	//static public function draw(mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void	{
		//if ( _model )
			//_model.draw( mvp, $context, $isChild, $alpha )
	//}
	
	static public function hide():void {
		if ( _model ) {
			//Log.out( "Axes.hide: " + VoxelModel.selectedModel , Log.WARN );
			_model.instanceInfo.visible = false
		}
	}
	
	static public function show():void {
		if ( _model ) {
			//Log.out( "Axes.show: " + VoxelModel.selectedModel , Log.WARN );
			_model.instanceInfo.visible = true
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
	
	
	public function Axes( instanceInfo:InstanceInfo ) { 
		super( instanceInfo )
	}
	override public	function get selected():Boolean 					{ return false; }
	override public	function set selected(val:Boolean):void  			{ _selected = false; }
	
}
}
