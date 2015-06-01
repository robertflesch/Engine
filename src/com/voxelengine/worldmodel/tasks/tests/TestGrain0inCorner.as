/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.tests
{
	import com.voxelengine.worldmodel.Biomes;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.Globals;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class TestGrain0inCorner extends LandscapeTask 
	{		
		public function TestGrain0inCorner( guid:String,layer:LayerInfo ):void {
			trace( "TestGrain0inCorner of type: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );					
			super(guid, layer);
		}
		
		override public function start():void {
            super.start() // AbstractTask will send event
			
			var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Solid Cube of any grain size
			//////////////////////////////////////////////////////////
			var grain_size:int = 0;
			var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _modelGuid );
			var gc:GrainCursor = GrainCursorPool.poolGet(vm.oxel.size_of_grain());

			var max:uint = gc.edgeval();
			var oxel:Oxel;
			
			
			gc.set_values( 0, 0, 0, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( 0, 0, max, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( 0, max, 0, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( 0, max, max, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( max, 0, 0, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( max, 0, max, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( max, max, 0, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			gc.set_values( max, max, max, gc.grain );
			vm.write( gc, TypeInfo.STONE );
			
			trace( "TestGrain0inCorner - took: "  + (getTimer() - timer) );					
            super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
