/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateCube extends LandscapeTask 
	{	
		static public function script():Object {
			var obj:Object = new Object();
			var model:Object = new Object();
			var biomes:Object = new Object();
			var layers:Vector.<Object> = new Vector.<Object>();
			var layer:Object = new Object();
			
			obj.model = model;
			model.editable = true;
			model.template = true;
			model.grainSize = 4;
			model.biomes = biomes;
			biomes.layers = layers;
			layers[0] = layer;
			layer.functionName = "GenerateCube";
			layer.type = "SAND"
			layer.range = 0;
			layer.offset = 0;
			
			return obj;
		}
		
		public function GenerateCube( guid:String, layer:LayerInfo ):void {
			//Log.out( "GenerateCube.construct of type: " + (Globals.Info[layer.type].name.toUpperCase()) );					
			super(guid, layer, "GenerateCube");
		}
		
		override public function start():void 
		{
            super.start() // AbstractTask will send event
			
			var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Solid Cube of any grain size
			//////////////////////////////////////////////////////////
			const root_grain_size:int = _layer.offset;
			const baseLightLevel:int = 51;
			var oxel:Oxel = Oxel.initializeRoot( root_grain_size, baseLightLevel );
			//
			var min_grain_size:int = root_grain_size - _layer.range;
			if ( 0 > min_grain_size || min_grain_size > root_grain_size || ( 8 < (root_grain_size - min_grain_size)) )
			{
				min_grain_size = Math.max( 0, root_grain_size - 4 );
				Log.out( "GenerateCube.start - WARNING - Adjusting range: " + min_grain_size, Log.WARN );
			}

			//trace("GenerateCube.start on rootGrain of max size: " + root_grain_size + "  Filling with grain of size: " + min_grain_size + " of type: " + Globals.Info[_layer.type].name );
			var loco:GrainCursor = GrainCursorPool.poolGet(root_grain_size);
			var size:int = 1 << (root_grain_size - min_grain_size);
			for ( var x:int = 0; x < size; x++ ) {
				for ( var y:int = 0; y < size; y++ ) {
					for ( var z:int = 0; z < size; z++ ) {
						loco.set_values( x, y, z, min_grain_size )
						oxel.write( _instanceGuid, loco, _layer.type );
						//vm.write( loco, _layer.type, true );
					}
				}
			}
			oxel.dirty = true;
			// CRITICAL STEP. when restoring the oxel, it expects to have faces, not dirty faces
			// So this step turns the dirty faces into real faces.
			// for multistep builds I will have to ponder this more.
			oxel.facesBuildWater();
			oxel.facesBuild();

			
			GrainCursorPool.poolDispose( loco );
			var ba:ByteArray = VoxelModel.oxelAsBasicModel( oxel );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, 0, Globals.IVM_EXT, _instanceGuid, null, ba ) );
			
			//Log.out( "GenerateCube.start - took: "  + (getTimer() - timer) );					
            super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
