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
		public function Avatar( instanceInfo:InstanceInfo, mi:ModelInfo, $vmm:VoxelModelMetadata ) 
		{ 
			trace( "Avatar CREATED" );
			super( instanceInfo, mi, $vmm );
		}
	}
}