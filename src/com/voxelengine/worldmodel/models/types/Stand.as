/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.*;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * The world model holds the active oxels
	 */
	public class Stand extends VoxelModel 
	{
		//Stand
		//Stand
		//Sight
		static private var _reloadSpeed:int;
		
		public function Stand( $ii:InstanceInfo ) 
		{ 
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

		static public function buildExportObject( obj:Object ):Object {
			VoxelModel.buildExportObject( obj );
			obj.stand 					= new Object();
			obj.stand.reloadSpeed 		= _reloadSpeed;

			return obj;
		}


	}
}
