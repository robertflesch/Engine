/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.worldmodel.Region;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import com.developmentarc.core.tasks.tasks.ITask;
	import com.developmentarc.core.tasks.groups.TaskGroup;
	
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.TypeInfo;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	
	public class CarveTunnel extends LandscapeTask 
	{		
		public var startLoc:Vector3D;
		public var view:Vector3D;
		public var radiusMultiplierMax:Number = 24;
		public var radiusMultiplierMin:Number = 0.85;
		public var stepSize:int = 24;
		
		static private var _crossList:Vector.<Vector3D>;
		static private const CROSS_LIST_SIZE:int = 26;
		
		static public function contructor( $guid:String, $start:Vector3D, $view:Vector3D, $type:int, $length:int, $radius:int, $minGrain:int = 4 ):void {
			
			//public function LayerInfo( functionName:String = null, data:String = "", type:int = 0 , range:int = 0, offset:int = 0, optional1:String = "", optional2:int = 0 )
			var layer:LayerInfo = new LayerInfo( "CarveTunnel", "", $type, $length, $radius, "", $minGrain );
			var ct:CarveTunnel = new CarveTunnel( $guid, layer );
			ct.startLoc = $start.clone();
			ct.view = $view.clone();
			var taskGroup:TaskGroup = new TaskGroup("CarveTunnel for " + $guid, 2);
			taskGroup.addTask( ct );
			Globals.taskController.addTask( taskGroup );
		}
		
		public function CarveTunnel( guid:String,layer:LayerInfo ):void {
			super(guid,layer);
		}
		
		override public function start():void {
            super.start(); // AbstractTask will send event
			var timer:int = getTimer();
			var vm:VoxelModel = getVoxelModel();
			if ( !vm ) {
				super.complete(); // AbstractTask will send event
				return;
			}
			
            var tunnelLength:int =_layer.range;
            var tunnelRadius:int =_layer.offset;
			var voxelType:int = _layer.type;
			var minGrain:int = _layer.optionalInt;
			
			trace( "CarveTunnel.start - carving tunnel of type " + (TypeInfo.typeInfo[voxelType].name.toUpperCase()) + " starting at x: " + startLoc.x + "  y: " + startLoc.y + "  z: " + startLoc.z );					
			
			view.scaleBy( stepSize );
			for ( var i:int = 1; i < tunnelLength / stepSize; i++ ) {
				
				var radius:int = Math.min( tunnelRadius * radiusMultiplierMin, Math.random() * tunnelRadius * radiusMultiplierMax );
				vm.modelInfo.oxelPersistence.oxel.write_sphere( _modelGuid, startLoc.x, startLoc.y, startLoc.z, radius, TypeInfo.AIR, minGrain );
				startLoc.x += view.x + rndOffset( tunnelRadius );
				startLoc.y += view.y + rndOffset( tunnelRadius );
				startLoc.z += view.z + rndOffset( tunnelRadius );
			}

			trace( "CarveTunnel - took: " + (getTimer() - timer) + " in queue for: " + (timer - _startTime)  );
			Oxel.merge( vm.modelInfo.oxelPersistence.oxel );
            super.complete(); // AbstractTask will send event
		}
		
		private function rndOffset( $max:int ):int {
			
			var offset:int = 0.5 < Math.random() ? -Math.random() * $max/2 : Math.random() * $max/2;
			//trace( "rndOffset: " + offset );
			return offset;
		}

	}
}