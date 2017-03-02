/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.ModelInfoEvent;
	import com.voxelengine.events.OxelDataEvent;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.biomes.*;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;

import flash.utils.getTimer;

	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class MergeLayer extends LandscapeTask 
	{		
		public function MergeLayer( $guid:String, $layer:LayerInfo ):void {
			super( $guid, $layer, "MergeLayer" );
			Log.out( "MergeLayer");
		}
		
		override public function start():void {
            super.start(); // AbstractTask will send event
			Log.out( "MergeLayer.start: " );
			// is it  ready?
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _modelGuid, null ) );
		}
		
		private function oxelDataRetrieved(e:OxelDataEvent):void {
			Log.out( "MergeLayer.oxelDataRetrieved:");
			if ( e.modelGuid == _modelGuid ) {
				OxelDataEvent.removeListener( OxelDataEvent.OXEL_READY, oxelDataRetrieved );
				var oxel:Oxel = e.oxelData.oxel;
				processOxel( oxel )
			}
		}
		
		private function modelInfoResult(e:ModelInfoEvent):void {
			Log.out( "MergeLayer.modelInfoResult:" );
			if ( e.modelGuid == _modelGuid ) {
				if ( !e.vmi || !e.vmi.oxelPersistance || !e.vmi.oxelPersistance.oxel ) {
					ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
					OxelDataEvent.addListener( OxelDataEvent.OXEL_READY, oxelDataRetrieved );		
					Log.out( "MergeLayer.modelInfoResult = no oxel found, waiting on OXEL_READY", Log.WARN );
					// error handling???
					// what if it never loads?
					return
				}
				var oxel:Oxel = e.vmi.oxelPersistance.oxel;
				processOxel( oxel )
			}
		}
		
		private function processOxel( $oxel:Oxel ):void {
			Log.out( "MergeLayer.processOxel:" );

			var timer:int = getTimer();
			Log.out( "MergeLayer - merging: ");
			$oxel.mergeRecursive();
			Log.out( "MergeLayer - merging recovered: " + Oxel.nodes + " took: " + (getTimer() - timer), Log.DEBUG );
			Oxel.nodes = 0;
			$oxel.mergeRecursive();
			Log.out( "MergeLayer - merging recovered: " + Oxel.nodes + " took: " + (getTimer() - timer), Log.DEBUG );
			timer = getTimer();
			Oxel.nodes = 0;
			$oxel.mergeRecursive();
			Log.out( "MergeLayer - merging 2 recovered: " + Oxel.nodes + " took: " + (getTimer() - timer), Log.DEBUG );
			$oxel.chunkGet().visitor( _modelGuid, VisitorFunctions.rebuild, "Oxel.rebuild" );

			var vm:VoxelModel = getVoxelModel();
			if ( vm )
				vm.complete = true;
				
			vm.modelInfo.oxelPersistance.changed = true;
			vm.modelInfo.oxelPersistance.save();
			
            super.complete(); // AbstractTask will send event
			
		}
	}
}