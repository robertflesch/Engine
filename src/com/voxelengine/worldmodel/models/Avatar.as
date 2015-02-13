package com.voxelengine.worldmodel.models
{
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ControllableVoxelModel;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	import com.voxelengine.worldmodel.models.ModelInfo;

    public class Avatar extends ControllableVoxelModel
    {
		public function Avatar( instanceInfo:InstanceInfo ) 
		{ 
			trace( "Avatar CREATED" );
			super( instanceInfo );
		}
		
		override public function init( $mi:ModelInfo, $vmm:VoxelModelMetadata, $initializeRoot:Boolean = true ):void {
			super.init( $mi, $vmm );
		}
	}
}