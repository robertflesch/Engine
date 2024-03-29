/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.flowtasks
{
	import com.developmentarc.core.tasks.tasks.AbstractTask;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.oxel.FlowInfo;
	import com.voxelengine.worldmodel.oxel.Oxel;
	
	// * @author Robert Flesch
	public class FlowTask extends AbstractTask 
	{		
		private static var _s_flowInfo:FlowInfo = new FlowInfo();
		
		protected var _guid:String;
		protected var _gc:GrainCursor;
		protected var _type:int;
		protected var _ready:Boolean = false;
		
		public static const TASK_TYPE:String = "FLOW_TASK";
        public static const TASK_PRIORITY:int = 64000;
		
		public function FlowTask( $instanceGuid:String, $gc:GrainCursor, $type:int, $taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
			// The model containing the grain 
			_guid = $instanceGuid;
			// the grain id
			_gc = GrainCursorPool.poolGet( $gc.bound );
			_gc.copyFrom( $gc );
			// the type it is to be changed to
			_type = $type;
			
			super($taskType, $taskPriority);
		}

		protected function neighborGetOrCreate( flowOxel:Oxel, flowIntoNeighbor:Oxel ):Oxel {
			Log.out( "FlowTask.neighborGetOrCreate - REFACTOR", Log.WARN );
			var flowIntoTarget:Oxel;
			var gct:GrainCursor = GrainCursorPool.poolGet( flowOxel.gc.bound );
			// this is oxel next to the one we want, but the flowIntoNeighbor might be a larger grain.
			// so find the address we want, then getChild on that oxel. Which causes the oxel to break up if needed.
			gct.copyFrom( flowOxel.gc );
			// move cursor to oxel we want.
//			_s_flowInfo.flowInfoRaw = _flowInfoRaw
//			gct.move( _s_flowInfo.direction );
			// now get the possibly reduced oxel we want.
			flowIntoTarget = flowIntoNeighbor.childGetOrCreate( gct );
			GrainCursorPool.poolDispose( gct );
			return flowIntoTarget;
		}
		
		override public function complete():void
		{
			GrainCursorPool.poolDispose( _gc );
			super.complete();
		}
		
		public function get type():int { return _type; }
		
		override public function toString():String {
			var output:String =  _guid;
			if ( _gc )
				output += "  gc: " + _gc.toString();
			output += "  type: " + _type;
			return output
		}

	}
}