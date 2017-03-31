/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.models.InstanceInfo;

public class Propeller extends VoxelModel
{
	// Todo: This needs to be global?
	static private const SHIP_PROP:String 		= "prop";

	// Todo: From metadata (someday)
	private var _rotationRate:int = 1440;

	public function Propeller(instanceInfo:InstanceInfo )  {
		super( instanceInfo);
	}

	static public function buildExportObject( $obj:Object, $model:* ):Object {
		VoxelModel.buildExportObject( $obj, $model );
		$obj.propeller = {};
		var thisModel:Propeller = $model as Propeller;
		$obj.propeller.rotationRate = thisModel._rotationRate;
		return $obj;
	}

	override protected function processClassJson():void {
		super.processClassJson();
		if ( modelInfo.dbo.propeller )
		{
			var propInfo:Object = modelInfo.dbo.Propeller;
			if ( propInfo.rotationRate )
				_rotationRate = propInfo.rotationRate;
		}
		else
			trace( "Propeller.processClassJson - NO Engine INFO FOUND - Setting to defaults" );

//			SoundBank.getSound( _soundFile ); // Preload the sound file
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
