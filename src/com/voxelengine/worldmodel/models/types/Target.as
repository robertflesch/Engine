/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;

import flash.geom.Vector3D;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	import com.voxelengine.events.TargetEvent;
	import com.voxelengine.events.ImpactEvent;
	
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.*;
	
	//import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * The world model holds the active oxels
	 */
	public class Target extends VoxelModel 
	{
		private var _pointValue:int = 10;
		
		public function Target( instanceInfo:InstanceInfo ) 
		{ 
			super( instanceInfo );
		}
		
		override public function init( $mi:ModelInfo, $buildState:String = ModelMakerBase.MAKING ):void {
			super.init( $mi, $buildState );
			
			Globals.g_app.dispatchEvent( new TargetEvent( TargetEvent.CREATED, instanceInfo.instanceGuid, _pointValue ) );
		}

		// I removed the responses, not sure what should be done here.
		//override public function explosionResponse( center:Vector3D, ee:ImpactEvent ):void
		//{
			/*
			var ba:ByteArray = Globals.findIVM( modelInfo.biomes.layers[0].data );
			statisics.gather( ba, grain );
			statisics.statsPrint();
			var oldCount:int = statisics.countInMeters;
			trace( "old count in meters: " + oldCount );
			
//			super.explosionResponse( center, ee );
			

			var newBa:ByteArray = new ByteArray();
			newBa.clear();
			oxel.writeData( newBa );
			newBa.position = 0;
			statisics.gather( newBa, grain );
			statisics.statsPrint();
			var newCount:int = statisics.countInMeters;
			trace( "new count in meters: " + newCount );
			if ( 0 == newCount )
				Globals.g_app.dispatchEvent( new TargetEvent( TargetEvent.DESTROYED, instanceInfo.instanceGuid, 10 ) );
			else
				Globals.g_app.dispatchEvent( new TargetEvent( TargetEvent.DAMAGED, instanceInfo.instanceGuid, 10 ) );
			*/				
			//Globals.g_app.dispatchEvent( new TargetEvent( TargetEvent.DESTROYED, instanceInfo.instanceGuid, _pointValue ) );
//			explode(1);	
			//instanceInfo.dead = true;
		//}
	}
}
