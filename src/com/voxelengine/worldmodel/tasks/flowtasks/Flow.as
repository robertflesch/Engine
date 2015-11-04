/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.flowtasks
{
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.events.TimerEvent;

	import com.developmentarc.core.tasks.events.TaskEvent;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.pools.FlowInfoPool;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.InteractionParams;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.TypeInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.GrainCursor;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.oxel.FlowInfo;
	import com.voxelengine.worldmodel.oxel.FlowScaling;
	import com.voxelengine.worldmodel.tasks.flowtasks.FlowTask;


	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class Flow extends FlowTask 
	{		
		static public function addTask( $instanceGuid:String, $gc:GrainCursor, $type:int, $flowInfoRaw:uint, $taskPriority:int ):void 
		{
			if ( !TypeInfo.typeInfo[$type].flowable ) {
				Log.out( "Flow.addTask - adding task for non flowable type: " + $type, Log.WARN );
				return
			}
			if ( 0 == ( ($flowInfoRaw & 0x000f0000) >> 16  ) ) {
				Log.out( "Flow.addTask - NO FLOW TYPE FOUND", Log.WARN );
			}
			var f:Flow = new Flow( $instanceGuid, $gc, $type, $flowInfoRaw, $gc.toID(), $taskPriority );
			f.selfOverride = true;
			Globals.g_flowTaskController.addTask( f );
		}
		
		public function Flow( $instanceGuid:String, $gc:GrainCursor, $type:int, $flowInfoRaw:int, $taskType:String, $taskPriority:int ):void {
			Log.out( "Flow.create flowInfo: " + $flowInfoRaw );
			_flowInfoRaw = $flowInfoRaw;
			super( $instanceGuid, $gc, $type, $taskType, $taskPriority );
			
			var pt:Timer = new Timer( 1000, 1 );
			pt.addEventListener(TimerEvent.TIMER, timeout );
			pt.start();
		}
		
		override public function get ready():Boolean { return _ready; }
		
		private function timeout(e:TimerEvent):void {
			_ready = true;
			dispatchEvent(new TaskEvent(TaskEvent.TASK_READY));
		}
		
		override public function start():void {
			super.start();
			
			var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
			if ( vm ) {
				var $flowFromOxel:Oxel = vm.modelInfo.data.oxel.childGetOrCreate( _gc );
				if ( null == $flowFromOxel  )
					return;
				if ( null == $flowFromOxel.flowInfo  )
					return;
				if ( !FlowInfo.validateData( _flowInfoRaw )	) {
					Log.out( "Flow.start - _flowInfoRaw - flow data invalid", Log.WARN );
					return; }
				if ( !FlowInfo.validateData( $flowFromOxel.flowInfo.flowInfoRaw )	) {
					Log.out( "Flow.start - $flowFromOxel.flowInfo.flowInfoRaw - flow data invalid", Log.WARN );
					return; }
				
				var flowType:uint = FlowInfo.getFlowType( _flowInfoRaw );
				//Log.out( "Flow.start - flowable oxel of type: " + ft );
				if ( FlowInfo.FLOW_TYPE_CONTINUOUS == flowType )
					flowStartContinous($flowFromOxel);
				else if ( FlowInfo.FLOW_TYPE_MELT == flowType )
					flowStartMelt($flowFromOxel);
				else if ( FlowInfo.FLOW_TYPE_SPRING == flowType )
					flowStartSpring($flowFromOxel);
				else {
					Log.out( "Flow.start - NO FLOW TYPE FOUND ft: " + flowType + " using continuous flow", Log.WARN );
					$flowFromOxel.flowInfo.type = FlowInfo.FLOW_TYPE_CONTINUOUS
					flowStartContinous($flowFromOxel)
				}
					
				//scale( $flowFromOxel );
			}
			else
				Log.out( "Flow.start - VoxelModel not found: " + _guid, Log.ERROR );
				
			super.complete();
			//Log.out( "Flow.start - Complete time: " + (getTimer() - timeStart) );
		}

		private function writeFlowTypeAndScaleNeighbors( $flowIntoOxel:Oxel ):void 
		{
			// I can only flow into AIR, everything else I interact with
			$flowIntoOxel.changeOxel( _guid, $flowIntoOxel.gc, type )
			$flowIntoOxel.flowInfo.flowScaling.calculate( $flowIntoOxel );
		
			var flowUnder:Oxel = $flowIntoOxel.neighbor( Globals.POSY );
			var flowOver:Oxel = $flowIntoOxel.neighbor( Globals.NEGY );
			// if I flow under another of the same type
			if ( Globals.BAD_OXEL != flowUnder ) {
				if ( flowUnder.type == $flowIntoOxel.type ) {
					flowUnder.flowInfo.flowScaling.reset( flowUnder, true )
					flowUnder.flowInfo.inheritFlowMax( $flowIntoOxel.flowInfo )
					flowUnder.flowInfo.flowScaling.neighborsRecalc( flowUnder, true );
				} else {
					// does the tasks flow type I interact with the type over us?
					var ipu:InteractionParams = TypeInfo.typeInfo[type].interactions.IOGet( TypeInfo.typeInfo[flowUnder.type].name );
					if ( "AIR" != ipu.type ) {
						flowUnder.flowInfo.flowScaling.reset( flowUnder, true )
						flowUnder.flowInfo.flowScaling.neighborsRecalc( flowUnder, true );
					}
				}
			}
			// if I flow over another oxel of the same type, reset its scaling
			if ( Globals.BAD_OXEL != flowOver ) {
				if ( flowOver.type == $flowIntoOxel.type ) {
					flowOver.flowInfo.flowScaling.reset( flowOver, true )
					flowOver.flowInfo.inheritFlowMax( $flowIntoOxel.flowInfo )
					flowOver.flowInfo.flowScaling.neighborsRecalc( flowOver, true );
				} else {
					// does the tasks flow type I interact with the type under us?
					// where else do I interact? Can it be moved here?
					var ipo:InteractionParams = TypeInfo.typeInfo[type].interactions.IOGet( TypeInfo.typeInfo[flowOver.type].name );
					if ( "AIR" != ipo.type ) {
						flowOver.flowInfo.flowScaling.reset( flowOver, true )
						flowOver.flowInfo.flowScaling.neighborsRecalc( flowOver, true );
					}
				}
			}
				
			// scaling was happening once about in the scaleCalculate, and again here.
			$flowIntoOxel.flowInfo.flowScaling.neighborsRecalc( $flowIntoOxel, false );
		}		
		
		private function flowStartSpring($flowFromOxel:Oxel):void { }
		
		static private const MIN_MELT_GRAIN:int = 2;
		private function flowStartMelt( $flowFromOxel:Oxel ):void {
			// Figure out what direction I can flow in.
			// Crack oxel and send 1/8 down in flow direction
			// go from 1,1,1 to 0,0,0 for flow order
			// each child voxel should try to flow at least 8 before stopping
			if ( MIN_MELT_GRAIN > $flowFromOxel.gc.grain )
				return;
				
//			FlowFlop.addTask( _guid, $flowFromOxel.gc, $flowFromOxel.type, $flowFromOxel.flowInfo, 1 );
		}

		private function flowStartContinous($flowFromOxel:Oxel):void {
			// Prefer going down if possible (or up for floatium)
			var floatiumTypeID:uint = TypeInfo.getTypeId( "floatium" );
			var flowCandidates:Vector.<FlowCandidate> = new Vector.<FlowCandidate>;
			var partial:Boolean = false;
			if ( floatiumTypeID == type )
				partial = canFlowInto( $flowFromOxel, Globals.POSY, flowCandidates );
			else
				partial = canFlowInto( $flowFromOxel, Globals.NEGY, flowCandidates );
				
			// if there is water below us, dont do anything
			if ( 0 == flowCandidates.length && partial )
				return;
			// if we found a down/up, add that as a priority
			else if ( 0 < flowCandidates.length )
			{
				flowTasksAdd( flowCandidates, true, $flowFromOxel.flowInfo );
				// if we only went partially down, try the sides	
				if ( false == partial )
					return;
				// reset list
				flowCandidates.length = 0;	
			}
				
			// no downs found, so check outs
			if ( 0 == flowCandidates.length )
			{
				// check sides once
				canFlowInto( $flowFromOxel, Globals.POSX, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.NEGX, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.POSZ, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.NEGZ, flowCandidates );
				if ( 0 < flowCandidates.length ) {
					flowTasksAdd( flowCandidates, false, $flowFromOxel.flowInfo );
				}
			}
		}
		
		private function flowTasksAdd( $fc:Vector.<FlowCandidate>, $upOrDown:Boolean, $flowInfo:FlowInfo ):void {
			for each ( var flowTest:FlowCandidate in $fc )
			{
				//Log.out( "Oxel.flowTaskAdd - $count: " + $countDown + "  countOut: " + $countOut + " gc data: " + flowCanditate.gc.toString() + " tasks: " + (Globals.g_flowTaskController.queueSize() + 1) );
				var	taskPriority:int = 3;
				if ( $upOrDown )
					taskPriority = 1;
				
				// why no flow info?
				if (  null == flowTest.flowCandidate.flowInfo )
					flowTest.flowCandidate.flowInfo = FlowInfoPool.poolGet()

				var fi:FlowInfo = flowTest.flowCandidate.flowInfo
				fi.copy( $flowInfo )
				fi.direction = flowTest.dir
				if ( 0 == fi.out )
					continue
				if ( 0 == fi.down )
					continue
					
				writeFlowTypeAndScaleNeighbors( flowTest.flowCandidate )
				Flow.addTask( _guid, flowTest.flowCandidate.gc, type, fi.flowInfoRaw, taskPriority + 1 )
			}
		}
		
		private const MIN_FLOW_GRAIN:int = 2;
		private function canFlowInto( flowOxel:Oxel, $face:int, $fc:Vector.<FlowCandidate> ):Boolean {
		
			var co:Oxel = flowOxel.neighbor($face);
			var partial:Boolean = false;
			var ft:FlowCandidate = null;
			if ( Globals.BAD_OXEL != co && co.gc && co.gc.grain >= MIN_FLOW_GRAIN )
			{
				// if our neighbor is air, just flow into it.o
				if ( co.type == TypeInfo.AIR && !co.childrenHas() ) {
					// Our neighbor oxel might be larger then this oxel
					// in which case just ask for oxel of same size
					if ( co.gc.grain == flowOxel.gc.grain ) {
						ft = new FlowCandidate();
						ft.dir = $face;
						ft.flowCandidate = co;
						$fc.push( ft );
					}
					else {
						// neighbor might be larger, never smaller
						var gct:GrainCursor = GrainCursorPool.poolGet( flowOxel.gc.bound );
						gct.copyFrom( flowOxel.gc );
						gct.move( $face );
						// getChild will crack the neighbor, if neighbor was larger to start
						var crackedOxel:Oxel = co.childGetOrCreate( gct );
						GrainCursorPool.poolDispose( gct );
						if ( Globals.BAD_OXEL != crackedOxel )
						{
							ft = new FlowCandidate();
							ft.dir = $face;
							ft.flowCandidate = crackedOxel;
							$fc.push( ft );
						}
					}
				}
				// if the neighbor is a flowable type, look up its interaction with that type
				else if ( TypeInfo.typeInfo[co.type].flowable ) {
					if ( co.type != type ) {
						//Log.out( "Oxel.flowable - 2 Different flow types here! getting IP for: " + Globals.Info[type].name + "  with " + Globals.Info[co.type].name );
						
						var ip:InteractionParams = TypeInfo.typeInfo[type].interactions.IOGet( TypeInfo.typeInfo[co.type].name );
						var writeType:int = TypeInfo.getTypeId( ip.type );
						if ( type != writeType ) {
							if ( TypeInfo.typeInfo[writeType].flowable ) {
								// if write type is same as flow type, add it.
								if ( type == writeType ) {
									ft = new FlowCandidate();
									ft.dir = $face;
									ft.flowCandidate = co;
									$fc.push( ft );
								}
							}
							else {
								// changed types are not flowable
								co.write( _guid, co.gc, writeType, false );
								//scale( co )
							}
						}
					}
					else
					{
						//Log.out( "Oxel.flowable - ALREADY " + Globals.Info[co.type].name + " here" );
						if ( TypeInfo.getTypeId( "floatium" ) == co.type ) {
							// there is floatium above us, we should not flow out.
							if ( Globals.POSY == $face )
								partial = true;
						}
						else {
							// there is water below us, we should not flow out.
							if ( Globals.NEGY == $face )
								partial = true;
						}
					}
				}
				else if ( co.childrenHas() ) {
					const dchildren:Vector.<Oxel> = co.childrenForDirection( Oxel.face_get_opposite( $face ) );
					for each ( var dchild:Oxel in dchildren )  {
						if ( TypeInfo.AIR == dchild.type ) {
							if ( TypeInfo.getTypeId( "floatium" ) == type ) {
								ft = new FlowCandidate();
								ft.dir = $face;
								ft.flowCandidate = dchild;
								$fc.push( ft );
								partial = true;
								
							}
							else if ( flowOxel.gc.grainY == dchild.gc.grainY && flowOxel.gc.grain == dchild.gc.grain ) {
								ft = new FlowCandidate();
								ft.dir = $face;
								ft.flowCandidate = dchild;
								$fc.push( ft );
								partial = true;
							}
						}
							
					}
				}
			}
			return partial;
		}
		/*
		static private const FLOW_NO_FACE_FOUND:int = -1;
		private function flowFindMeltableDirection($flowFromOxel:Oxel):int {
			for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
				if ( Globals.POSY == face )
					continue;
					
				var no:Oxel = $flowFromOxel.neighbor( face );
				if ( TypeInfo.AIR == no.type )
					return face;
			}
			
			return FLOW_NO_FACE_FOUND;
		}
		*/
		
	}
}

import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.Globals;
internal class FlowCandidate
{
	public var flowCandidate:Oxel = null;
	public var dir:int = Globals.ALL_DIRS;
}