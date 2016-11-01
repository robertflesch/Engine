/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.adobe.utils.Hex;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.OxelDataEvent;
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.worldmodel.models.OxelPersistance;
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
	import com.voxelengine.worldmodel.TypeInfo;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class GenerateCube extends LandscapeTask 
	{	
		static public function script( $grain:int = 6, $type:int = 0 ):Object {
			if ( 0 == $type )
				$type = TypeInfo.SAND;
			var model:Object = {};
			model.name = "GenerateCube";
			model.grainSize = $grain;
			model.biomes = new Object();
			model.biomes.layers = new Vector.<Object>();
			model.biomes.layers[0] = {};
			model.biomes.layers[0].functionName = "GenerateCube";
			model.biomes.layers[0].type = TypeInfo.name( $type );
			
			return model;
		}
		
		public function GenerateCube( $guid:String, layer:LayerInfo ):void {
			super($guid, layer, "GenerateCube");
			Log.out( "GenerateCube: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
		}
		
		override public function start():void 
		{
            super.start() // AbstractTask will send event
			Log.out( "GenerateCube.start: " + (TypeInfo.typeInfo[_layer.type].name.toUpperCase()) );
			
			var timer:int =  getTimer();

			Oxel.generateCube( _modelGuid, _layer );

			//Log.out( "GenerateCube.start - took: "  + (getTimer() - timer) );					
            super.complete() // AbstractTask will send event
		}
		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
