/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ControllableVoxelModel;
	import com.voxelengine.worldmodel.models.ModelMetadata;
	import com.voxelengine.worldmodel.models.ModelInfo;

    public class Avatar extends ControllableVoxelModel
    {
		public function Avatar( instanceInfo:InstanceInfo ) 
		{ 
			//Log.out( "Avatar CREATED" );
			super( instanceInfo );
		}
		
		override public function init( $mi:ModelInfo, $vmm:ModelMetadata, $initializeRoot:Boolean = true ):void {
			super.init( $mi, $vmm );
		}
	}
}