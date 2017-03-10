/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateSphere extends LandscapeTask 
	{		
		static public function script():Object {
			var model:Object = {};
			model.grainSize = 6;
			model.name = "GenerateSphere";
			model.biomes = {};
			model.biomes.layers = new Vector.<Object>();
			model.biomes.layers[0] = {};
			model.biomes.layers[0].functionName = "GenerateSphere";
			model.biomes.layers[0].type = "SAND";
			model.biomes.layers[0].range = 3;
			model.biomes.layers[0].offset = 7;
			
			return model;
		}
		
		public function GenerateSphere( guid:String,layer:LayerInfo ):void {
			//Log.out( "GenerateSphere.construct of type: " + (Globals.Info[layer.type].name.toUpperCase()) );					
			super(guid, layer, "GenerateSphere: " + (TypeInfo.typeInfo[layer.type].name.toUpperCase()) );
		}
		
		override public function start():void
		{
			super.start(); // AbstractTask will send event

			var timer:int = getTimer();
			
			//////////////////////////////////////////////////////////
			// Builds Sphere Cube of any grain size
			//////////////////////////////////////////////////////////
			const root_grain_size:int = _layer.offset;
			var oxel:Oxel = Oxel.initializeRoot( root_grain_size );
			//
			var min_grain_size:int = _layer.range;
			if ( 0 > min_grain_size || min_grain_size > (root_grain_size - 3) || ( 8 < (root_grain_size - min_grain_size)) )
			{
				min_grain_size = Math.max( 0, root_grain_size - 5 );
				Log.out( "GenerateSphere.start - WARNING - Adjusting range: " + min_grain_size, Log.WARN );
			}

			var c:int = oxel.size_in_world_coordinates() / 2;

			Log.out( "GenerateSphere.using params oxel.gc.bound: " + oxel.gc.bound + "  c: " + c + " min grain: " + min_grain_size, Log.WARN );
			oxel.write_sphere( _modelGuid, c, c, c, c, _layer.type, min_grain_size );

			oxel.dirty = true;
			// CRITICAL STEP FOR GENERATION TASKS. when drawing the oxel, it expects to have faces, not dirty faces
			// So this step turns the dirty faces into real faces.
			// for multistep builds I will have to ponder this more.
			//oxel.facesBuildWater();
			oxel.facesBuild();

			throw new Error( "REFACTOR = 2.22.17");
/*
			var ba:ByteArray = OxelPersistence.toByteArray( oxel );
			Log.out( "GenerateSphere finished modelGuid: " + _modelGuid );
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, 0, Globals.IVM_EXT, _modelGuid, null, ba ) );
*/
			//Log.out( "GenerateSphere.start - completed layer of type: " + (Globals.Info[_layer.type].name.toUpperCase()) + "  range: " + _layer.range + "  offset: " + _layer.offset + " took: " + (getTimer()-timer) + " in queue for: " + (timer-_startTime));
			super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}