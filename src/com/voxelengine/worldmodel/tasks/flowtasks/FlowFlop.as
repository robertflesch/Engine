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
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.OxelBad;


/*
 *  This function turns an oxel into this shape
 *  by writing to the surrounding oxels, and cutting off the top of the current oxel
 *
 *              ______
 *              |     |
 *              |NxPz |
 *              |_____|______|_____
 *              |            |     |
 *         _____|NxNz    PxNz|NxNz |
 *        |     |            |_____|
 *        |  PxPz|NxPz    PxPz|
 *        |_____|____________|
 *                     |     |
 *                     |NxNz |
 *                     |_____|
 *
 *
 *
 */

public class FlowFlop extends FlowTask  {
	private  static	const BOTTOM_LEVEL:int = 0;
	private  static	const TOP_LEVEL:int = 1;
	private var _flowInfo:FlowInfo;

	static public function addTask( $instanceGuid:String, gc:GrainCursor, $type:int, $flowInfo:FlowInfo, $taskPriority:int ):void
	{
		Globals.taskController.addTask( new FlowFlop( $instanceGuid, gc, $type, $flowInfo, FlowTask.TASK_TYPE, FlowTask.TASK_PRIORITY + $taskPriority ) );
	}

	public function FlowFlop( $instanceGuid:String, $gc:GrainCursor, $type:int, $flowInfo:FlowInfo, $taskType:String = TASK_TYPE, $taskPriority:int = TASK_PRIORITY ):void {
		//Log.out( "FlowFlop.create" );
		_flowInfo = $flowInfo;
		super( $instanceGuid, $gc, $type, $taskType, $taskPriority );

		var pt:Timer = new Timer( 1000, 0.25 );
		pt.addEventListener(TimerEvent.TIMER, timeout );
		pt.start();
	}

	/**
	 * Defines if the task is in a ready state.
	 */
	override public function get ready():Boolean { return _ready; }

	private function timeout(e:TimerEvent):void {
		_ready = true;
		dispatchEvent(new TaskEvent(TaskEvent.TASK_READY));
	}

	override public function start():void {
		super.start();

		var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _guid );
		main:if ( vm )
		{
			var flowOxel:Oxel = vm.modelInfo.oxelPersistence.oxel.childGetOrCreate( _gc );
			if ( null == flowOxel.gc )
				//Log.out( "FlowFlop.start - oxel released" );
				break main;
			else
			{
				// flop over the top
				var auto:Boolean = Globals.autoFlow;
				Globals.autoFlow = false;

				var changed:Boolean = false;
				var changedOxel:Oxel = null;
				var underOxel:Oxel = flowOxel.neighbor( Globals.NEGY );
				// TODO there is a partial flow case here
				if ( TypeInfo.AIR == underOxel.type )
				{
					var uchildren:Vector.<Oxel> = underOxel.childrenForDirection( Globals.POSY );
					var dchildren:Vector.<Oxel> = flowOxel.childrenForDirection( Globals.POSY );
					for ( var i:int = 0; i < 4; i++ )
					{
						if ( TypeInfo.AIR == uchildren[i].type )
						{
							changedOxel = flowDown( uchildren[i], dchildren[i] );
							if ( changedOxel ) {
								changed = true;
								flowTasksAdd( uchildren[i], false, uchildren[i].flowInfo )
							}
						}
						else
						{
							if ( 0 == i )
								flowOut( flowOxel, Globals.NEGZ, false );
							else if ( 1 == i )
								flowOut( flowOxel, Globals.POSX, false );
							else if ( 2 == i )
								flowOut( flowOxel, Globals.NEGX, false );
							else if ( 3 == i )
								flowOut( flowOxel, Globals.POSZ, false );
						}
					}
				}
				else
				{
					for each ( var dir:int in Globals.horizontalDirections )
					{
						changedOxel = flowOut( flowOxel, dir );
						if ( changedOxel ) {
							changed = true;
							flowTasksAdd( changedOxel, false, changedOxel.flowInfo )
						}
					}
				}

				// if nothing changed, and I have children, see if they can be merged
				if ( !changed && flowOxel.childrenHas() )
					flowOxel.checkForMerge();

				Globals.autoFlow = auto;
			}
		}
		else
		{
			Log.out( "FlowFlop.start - VoxelModel not found: " + _guid, Log.ERROR );
		}
		super.complete();
	}

	private function flowTasksAdd( flowTarget:Oxel, $upOrDown:Boolean, $flowInfo:FlowInfo ):void {
		//Log.out( "Oxel.flowTaskAdd - $count: " + $countDown + "  countOut: " + $countOut + " gc data: " + flowCanditate.gc.toString() + " tasks: " + (Globals.taskController.queueSize() + 1) );
		var	taskPriority:int = 0;
		if ( $upOrDown )
			taskPriority = 1;
		else
			taskPriority = 3;

		var fi:FlowInfo = new FlowInfo();
		fi.copy( $flowInfo );
		//fi.direction = flowTarget.
		if ( 0 == fi.out )
			return;

		FlowLimited.addTask( _guid, flowTarget.gc, type, fi, taskPriority )
	}

	private function flowDown( $toChild:Oxel, $fromChild:Oxel ):Oxel {

		$toChild.change( _guid, $toChild.gc, _type );
		$toChild.flowInfo.direction = Globals.NEGY;
		$fromChild.change( _guid, $fromChild.gc, TypeInfo.AIR );
		return $toChild;
	}

	private function flowOut( $flowOxel:Oxel, $dir:int, opposite:Boolean = true ):Oxel {
		var flowIntoChild:Oxel = null;
		var flowFromChild:Oxel = null;
		var flowIntoParent:Oxel = $flowOxel.neighbor( $dir );
		if ( OxelBad.INVALID_OXEL == flowIntoParent && TypeInfo.AIR == flowIntoParent.type )
		{
			var gct:GrainCursor = GrainCursorPool.poolGet( $flowOxel.gc.bound );
			// this is oxel next to the one we want, but the flowIntoParent might be a larger grain.
			// so find the address we want, then getChild on that oxel. Which causes the oxel to break up if needed.
			flowFromChild = $flowOxel.childGetFromDirection( $dir, BOTTOM_LEVEL, opposite );
			gct.copyFrom( flowFromChild.gc );
			// move cursor to oxel we want.
			gct.move( $dir );
			// now get the possibly reduced oxel we want.
			flowIntoChild = flowIntoParent.childGetOrCreate( gct );
			GrainCursorPool.poolDispose( gct );
			if ( TypeInfo.AIR == flowIntoChild.type )
			{
				flowIntoChild.change( _guid, flowIntoChild.gc, _type );
				flowIntoChild.flowInfo.direction = $dir;
				flowIntoChild.flowInfo.flowScaling.calculate( flowIntoChild );
				flowFromChild = $flowOxel.childGetFromDirection( $dir, TOP_LEVEL, opposite );
				flowFromChild.change( _guid, flowFromChild.gc, TypeInfo.AIR );
				return flowIntoChild;
			}
			else
			{
				opposite = !opposite;
				// The parent oxel has already been reduced to size we need
				flowFromChild = $flowOxel.childGetFromDirection( Oxel.face_get_opposite( $dir ), BOTTOM_LEVEL, opposite );
				if ( TypeInfo.AIR == flowIntoChild.type )
				{
					flowIntoChild.change( _guid, flowIntoChild.gc, _type );
					flowIntoChild.flowInfo.direction = $dir;
					flowIntoChild.flowInfo.flowScaling.calculate( flowIntoChild );
					flowFromChild = $flowOxel.childGetFromDirection( $dir, TOP_LEVEL, opposite );
					flowFromChild.change( _guid, flowFromChild.gc, TypeInfo.AIR );
					return flowIntoChild;
				}
			}
		}

		return null;
	}

	private function adjecentSideGet( $dir:int ):int {
		if ( Globals.POSX == $dir )
			return Globals.NEGZ;
		else if ( Globals.NEGX == $dir )
			return Globals.POSZ;
		else if ( Globals.POSZ == $dir )
			return Globals.POSX;
		else if ( Globals.NEGZ == $dir )
			return Globals.POSZ;
		return Globals.POSY;
	}
}
}