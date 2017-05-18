/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
		private var _vm:VoxelModel	// temp holder for VM, it is set to null when start routine exits.
		static public function addTask( $instanceGuid:String, $gc:GrainCursor, $type:int, $taskPriority:int ):void {
			// http://jacksondunstan.com/articles/2439 for a better assert
			if ( TypeInfo.INVALID == $type ) {
				Log.out( "Flow.addTask - cant add task for TypeInfo.INVALID", Log.WARN );
				return
			}
			
			if ( null == $instanceGuid || "" == $instanceGuid ) {
				Log.out( "Flow.addTask - cant add task for null or empty model guid", Log.WARN );
				return
			}
			if ( !TypeInfo.typeInfo[$type].flowable ) {
				Log.out( "Flow.addTask - adding task for non flowable type: " + $type, Log.WARN );
				return
			}
			var f:Flow = new Flow( $instanceGuid, $gc, $type, $gc.toID(), $taskPriority );
			f.selfOverride = true;
			Globals.taskController.addTask( f );
		}
		
		public function Flow( $instanceGuid:String, $gc:GrainCursor, $type:int, $taskType:String, $taskPriority:int ):void {
			super( $instanceGuid, $gc, $type, $taskType, $taskPriority );
			//Log.out( "Flow.create flow: " + toString() );
			var spreadInterval:int = TypeInfo.typeInfo[$type].spreadInterval // How fast this type spreads
			var pt:Timer = new Timer( spreadInterval, 1 );
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
			//Log.out( "Flow.start " + toString(), Log.WARN );
			_vm = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
			if ( _vm ) {
				var $flowFromOxel:Oxel = _vm.modelInfo.oxelPersistence.oxel.childGetOrCreate( _gc );
				if ( null == $flowFromOxel  ) {
					Log.out( "Flow.start - null == $flowFromOxel", Log.WARN );
					return; }
				if ( null == $flowFromOxel.flowInfo  ) {
					Log.out( "Flow.start - null == $flowFromOxel.flowInfo", Log.WARN );
					return; }
				
				var flowType:uint = $flowFromOxel.flowInfo.type
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
			}
			else
				Log.out( "Flow.start - VoxelModel not found: " + _guid, Log.ERROR );
				
			_vm = null	
			super.complete();
			//Log.out( "Flow.start - Complete time: " + (getTimer() - timeStart) );
		}
		
		private function flowStartSpring($flowFromOxel:Oxel):void { }
		
		static private const MIN_MELT_GRAIN:int = 2;
		private function flowStartMelt( $flowFromOxel:Oxel ):void {
			// Figure out what direction I can flow in.
			// Crack oxel and send 1/8 down in flow direction
			// go from 1,1,1 to 0,0,0 for flow order
			// each child voxel should try to flow at least 8 before stopping
			if ( MIN_MELT_GRAIN > $flowFromOxel.gc.grain )
				//$flowFromOxel.changeOxel( _guid, $flowFromOxel.gc, TypeInfo.AIR )
				_vm.write( $flowFromOxel.gc, TypeInfo.AIR )
				return;
				
			//FlowFlop.addTask( _guid, $flowFromOxel.gc, $flowFromOxel.type, $flowFromOxel.flowInfo, 1 );
			
			// so first the top layer should flow out.
			// what does flow out mean?
			// it means that the oxel should break into its children
			// then the bottom half of the oxels should test the space around them
			// if there is air, the should move to that space, and the oxel above them should move down.
		}

		private function flowStartContinous($flowFromOxel:Oxel):void {
			// Prefer going down if possible (or up for floatium)
			var floatiumTypeID:uint = TypeInfo.getTypeId( "floatium" );
			var flowCandidates:Vector.<FlowCandidate> = new Vector.<FlowCandidate>;
			
			if ( Globals.g_oxelBreakEnabled	)
				if ( $flowFromOxel.gc.evalGC( Globals.g_oxelBreakData ) )
					trace( "Flow.flowStartContinous - setGC breakpoint" )
					
			var downwardFlow:Boolean = false;
			if ( floatiumTypeID == type )
				downwardFlow = canFlowInto( $flowFromOxel, Globals.POSY, flowCandidates );
			else
				downwardFlow = canFlowInto( $flowFromOxel, Globals.NEGY, flowCandidates );
				
			// if we found a down/up, add that as a priority
			if ( 0 < flowCandidates.length ) {
				flowTasksAdd( flowCandidates, true, $flowFromOxel.flowInfo );
				// if we only went partially down, try the sides	
				if ( false == downwardFlow )
					return;
				// reset list
				flowCandidates.length = 0;	
			} else if ( downwardFlow ) {
				trace( "Flow.flowStartContinous - partial" )
				return
			}
				
			// no downs found, so check outs
//			if ( 0 == flowCandidates.length && 0 < $flowFromOxel.flowInfo.out) {
			if ( 0 == flowCandidates.length ) {
				// check sides once
				canFlowInto( $flowFromOxel, Globals.POSX, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.NEGX, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.POSZ, flowCandidates );
				canFlowInto( $flowFromOxel, Globals.NEGZ, flowCandidates );
				if ( 0 < flowCandidates.length ) {
					flowTasksAdd( flowCandidates, false, $flowFromOxel.flowInfo );
					//Log.out( "Flow.flowStartContinous adding: " + flowCandidates.length + " new flows" )
					return
				}
//				Log.out( "Flow.flowStartContinous NO new flows found" )
			}
		}
		
		private const MIN_FLOW_GRAIN:int = 2;
		private function canFlowInto( flowOxel:Oxel, $face:int, $fc:Vector.<FlowCandidate> ):Boolean {
		
			var no:Oxel = flowOxel.neighbor($face);
			var partial:Boolean = false;
			if ( Globals.BAD_OXEL != no && no.gc && no.gc.grain >= MIN_FLOW_GRAIN )
			{
				// if our neighbor is air, just flow into it.o
				if ( no.type == TypeInfo.AIR && !no.childrenHas() ) {
					// Our neighbor oxel might be larger then this oxel
					// in which case just ask for oxel of same size
					if ( no.gc.grain == flowOxel.gc.grain ) {
						$fc.push( new FlowCandidate( $face, no ) );
					}
					else {
						// neighbor might be larger, never smaller
						var gct:GrainCursor = GrainCursorPool.poolGet( flowOxel.gc.bound );
						gct.copyFrom( flowOxel.gc );
						gct.move( $face );
						// getChild will crack the neighbor, if neighbor was larger to start
						var crackedOxel:Oxel = no.childGetOrCreate( gct );
						GrainCursorPool.poolDispose( gct );
						if ( Globals.BAD_OXEL != crackedOxel )
							$fc.push( new FlowCandidate( $face, crackedOxel ) );
					}
				}
				// if the neighbor is a flowable type, look up its interaction with that type
				else if ( TypeInfo.typeInfo[no.type].flowable ) {
					if ( no.type != type ) {
						//Log.out( "Oxel.flowable - 2 Different flow types here! getting IP for: " + Globals.Info[type].name + "  with " + Globals.Info[no.type].name );
						
						interactWithFlowableType( no );
						partial = true
					}
					else {
						//Log.out( "Oxel.flowable - ALREADY " + Globals.Info[no.type].name + " here" );
						if ( TypeInfo.getTypeId( "floatium" ) == no.type ) {
							// there is floatium above us, we should not flow out.
							if ( Globals.POSY == $face )
								partial = true;
						}
						else {
							// there is water or lava or any other flowable type that is the same below us, we should not flow out.
							if ( Globals.NEGY == $face ) {
								if ( no.flowInfo.flowScaling.has() )
									no.flowInfo.flowScaling.reset( no )
									no.flowInfo.flowScaling.neighborsRecalc( no, false );
								partial = true;
							}
						}
					}
				}
				else if ( no.childrenHas() ) {
					attemptFlowIntoChildren( no, $face, $fc )
				}
			}
			return partial;
		}
		
		private function attemptFlowIntoChildren( $no:Oxel, $face:int, $fc:Vector.<FlowCandidate> ):Boolean {
			// 
			if ( MIN_FLOW_GRAIN + 1 > $no.gc.grain )
				return false
				
			var partial:Boolean = false;
			const dchildren:Vector.<Oxel> = $no.childrenForDirection( Oxel.face_get_opposite( $face ) );
			for each ( var dchild:Oxel in dchildren )  {
				if ( TypeInfo.AIR == dchild.type && !dchild.childrenHas() ) {
					if ( TypeInfo.getTypeId( "floatium" ) == type ) {
						$fc.push( new FlowCandidate( $face, dchild ) );
						partial = true;
					}
					// what was this if statement here?
					else { //if ( flowOxel.gc.grainY == dchild.gc.grainY && flowOxel.gc.grain == dchild.gc.grain ) {
						$fc.push( new FlowCandidate( $face, dchild ) );
						partial = true;
					}
				}
				else if ( TypeInfo.AIR == dchild.type && dchild.childrenHas() ) {
					partial = attemptFlowIntoChildren( dchild, $face, $fc )
				}
			}
			return partial
		}
		
		private function flowTasksAdd( $fc:Vector.<FlowCandidate>, $upOrDown:Boolean, $flowInfo:FlowInfo ):void {
			for each ( var flowTest:FlowCandidate in $fc ) {
				const stepSize:int = ( flowTest.flowCandidate.gc.size() / Globals.UNITS_PER_METER) * 4
				if ( !$upOrDown && 0 == $flowInfo.flowScaling.min() )
					continue
				
				//Log.out( "Oxel.flowTaskAdd - $count: " + $countDown + "  countOut: " + $countOut + " gc data: " + flowCanditate.gc.toString() + " tasks: " + (Globals.taskController.queueSize() + 1) );
				if (  null == flowTest.flowCandidate.flowInfo )
					flowTest.flowCandidate.flowInfo = FlowInfoPool.poolGet()

				// now set the flowInfo in the flowCandidate, which will be using in the changeOxel
				var fi:FlowInfo = flowTest.flowCandidate.flowInfo
				fi.copy( $flowInfo )
				fi.directionSetAndDecrement( flowTest.dir, stepSize )
					
				var	taskPriority:int = 3;
				if ( $upOrDown ) {
					taskPriority = 1
					flowTest.flowCandidate.flowInfo.flowScaling.reset()
					if ( 0 > fi.down )
						continue
					else if ( fi.changeType( stepSize ) ) {
						var newType:uint = TypeInfo.changeType( type )
						if ( TypeInfo.AIR == newType )
							continue
						else {	
							_type = newType
							fi.copy( TypeInfo.typeInfo[type].flowInfo )
						}
					}

				}
					
				//Log.out( "Flow.flowTasksAdd fi.type: " + fi.type + "  fi.out" + fi.out + "  fi.flowScaling.min " + fi.flowScaling.min() )
					
				writeFlowTypeAndScaleNeighbors( flowTest.flowCandidate )
				Flow.addTask( _guid, flowTest.flowCandidate.gc, type, taskPriority + 1 )
			}
		}
		
		private function writeFlowTypeAndScaleNeighbors( $flowIntoOxel:Oxel ):void 
		{
			// I can only flow into AIR, everything else I interact with
			//$flowIntoOxel.changeOxel( _guid, $flowIntoOxel.gc, type )
			_vm.write( $flowIntoOxel.gc, type )
			var flowOver:Oxel = $flowIntoOxel.neighbor( Globals.NEGY );
			var flowUnder:Oxel = $flowIntoOxel.neighbor( Globals.POSY );
			if ( TypeInfo.FIRE ==  type ) {
				flowOver.setOnFire( _guid )
				flowUnder.setOnFire( _guid )
				return
			}
			$flowIntoOxel.flowInfo.flowScaling.calculate( $flowIntoOxel );
		
			// if I flow under another of the same type
			if ( Globals.BAD_OXEL != flowUnder ) {
				if ( flowUnder.type == $flowIntoOxel.type ) {
					//flowUnder.flowInfo.flowScaling.reset( flowUnder, true )
					flowUnder.flowInfo.inheritFlowMax( $flowIntoOxel.flowInfo )
					$flowIntoOxel.flowInfo.flowScaling.reset( $flowIntoOxel, true )
					flowUnder.flowInfo.flowScaling.neighborsRecalc( flowUnder, true );
				} else {
					if ( flowUnder.childrenHas() ) 
						attemptInteractionWithChildren( flowUnder, Globals.NEGY )
					else
						interactRescale( flowUnder )
				}
			}
			// if I flow over another oxel of the same type, reset its scaling
			if ( Globals.BAD_OXEL != flowOver ) {
				if ( flowOver.type == $flowIntoOxel.type ) {
					flowOver.flowInfo.flowScaling.reset( flowOver, true )
					flowOver.flowInfo.inheritFlowMax( $flowIntoOxel.flowInfo )
					flowOver.flowInfo.flowScaling.reset( $flowIntoOxel, true )
					flowOver.flowInfo.flowScaling.neighborsRecalc( flowOver, true );
				} else {
					if ( flowOver.childrenHas() ) 
						attemptInteractionWithChildren( flowOver, Globals.NEGY )
					else
						interactRescale( flowOver )
				}
			}
				
			// scaling was happening once about in the scaleCalculate, and again here.
			$flowIntoOxel.flowInfo.flowScaling.neighborsRecalc( $flowIntoOxel, false );
		}		
		
		private function interactRescale( $interOxel:Oxel ):void {
			var ipo:InteractionParams = TypeInfo.typeInfo[type].interactions.IOGet( TypeInfo.typeInfo[$interOxel.type].name );
			if ( "AIR" != ipo.type && $interOxel.flowInfo && $interOxel.flowInfo.flowScaling.has() ) {
				$interOxel.flowInfo.flowScaling.reset( $interOxel, true )
				$interOxel.flowInfo.flowScaling.neighborsRecalc( $interOxel, true );
			}
		}
		
		private function attemptInteractionWithChildren( flowOver:Oxel, $face:int ):Boolean {
			if ( MIN_FLOW_GRAIN + 1 > flowOver.gc.grain )
				return false
				
			var partial:Boolean = false;
			const dchildren:Vector.<Oxel> = flowOver.childrenForDirection( Oxel.face_get_opposite( $face ) );
			for each ( var dchild:Oxel in dchildren )  {
				if ( TypeInfo.AIR != dchild.type && !dchild.childrenHas() ) {
					interactRescale( dchild )
				}
			}
			return partial
		}
		
		private function interactWithFlowableType( no:Oxel ):void  {
			var ip:InteractionParams = TypeInfo.typeInfo[type].interactions.IOGet( TypeInfo.typeInfo[no.type].name );
			var writeType:int = TypeInfo.getTypeId( ip.type );
			if ( type != writeType )
				// changed types are not flowable
				no.change( _guid, no.gc, writeType, false );
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
	
	public function FlowCandidate( $dir:int, $fc:Oxel ) {
		dir = $dir
		flowCandidate = $fc
	}
}