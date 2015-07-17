/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * The world model holds the active oxels
	 */
	public class Barrel extends VoxelModel 
	{
		public function Barrel( instanceInfo:InstanceInfo ) { 
			super( instanceInfo );
		}
		
		override protected function processClassJson():void {
			super.processClassJson();
			
			if ( modelInfo.dbo.barrel ) {
				var barrelInfo:Object = modelInfo.dbo.barrel;
			}
//			else
//				trace( "Stand - NO Stand INFO FOUND" );
		}
	}
}
