/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.models.*;

public class Stand extends VoxelModel
{
	//Stand
	//Stand
	//Sight
	private var _reloadSpeed:int;

	public function Stand( $ii:InstanceInfo ) {
		super( $ii );
	}

	override protected function processClassJson( $buildState:String ):void {
		super.processClassJson( $buildState );

		if ( modelInfo.dbo && modelInfo.dbo.stand )
		{
			var standInfo:Object = modelInfo.dbo.stand;
			if ( standInfo.reloadSpeed )
				_reloadSpeed = standInfo.reloadSpeed;
		}
//			else
//				trace( "Stand - NO Stand INFO FOUND" );
	}

	override public function buildExportObject():void {
		super.buildExportObject();
		modelInfo.dbo.stand = {};
		modelInfo.dbo.reloadSpeed = _reloadSpeed;
	}

}
}
