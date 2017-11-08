/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.Log;
import com.voxelengine.worldmodel.models.InstanceInfo;

public class Propeller extends VoxelModel
{
	static public const MODEL_PROPELLER:String = "MODEL_PROPELLER";
	static public function getAnimationClass():String { return MODEL_PROPELLER; }

	private var _rotationRate:int = 1440;

	public function Propeller(instanceInfo:InstanceInfo )  {
		super( instanceInfo);
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.propeller = {};
		modelInfo.dbo.propeller.rotationRate = _rotationRate;
	}

	override protected function processClassJson( $buildState:String ):void {
		super.processClassJson( $buildState );
		if ( modelInfo.dbo.propeller ) {
			var propInfo:Object = modelInfo.dbo.propeller;
			if ( propInfo.rotationRate )
				_rotationRate = propInfo.rotationRate;
		}
		else
			Log.out( "Propeller.processClassJson - NO Propeller INFO FOUND - Setting to defaults", Log.WARN );
	}

/*
	override public function start( $val:Number, $parentModel:VoxelModel, $useThrust:Boolean = true ):void
	{
		super.start( $val, $parentModel );
		for each ( var vm:VoxelModel in _children )
		{
			if ( -1 != vm.instanceInfo.name.search( "Propeller" ) )
			{
				vm.instanceInfo.addNamedTransform( 0, 0, $val * _rotationRate, -1, ModelTransform.ROTATION, SHIP_PROP );
			}
		}
	}

	override public function stop( $parentModel:VoxelModel, $useThrust:Boolean = true ):void
	{
		super.stop( $parentModel );
		for each ( var vm:VoxelModel in _children )
		{
			// find the children models with "Propeller" in them
			if ( -1 != vm.instanceInfo.name.search( "Propeller" ) )
				vm.instanceInfo.removeNamedTransform( ModelTransform.ROTATION, SHIP_PROP );
		}
	}
	*/
}
}
