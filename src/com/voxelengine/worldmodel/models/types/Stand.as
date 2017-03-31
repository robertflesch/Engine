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

	override protected function processClassJson():void {
		super.processClassJson();

		if ( modelInfo.dbo && modelInfo.dbo.stand )
		{
			var standInfo:Object = modelInfo.dbo.stand;
			if ( standInfo.reloadSpeed )
				_reloadSpeed = standInfo.reloadSpeed;
		}
//			else
//				trace( "Stand - NO Stand INFO FOUND" );
	}

	static public function buildExportObject( $obj:Object, $model:* ):Object {
		VoxelModel.buildExportObject( $obj, $model );
		$obj.stand = {};
		var thisModel:Stand = $model as Stand;
		$obj.stand.reloadSpeed = thisModel._reloadSpeed;
		return $obj;
	}

}
}
