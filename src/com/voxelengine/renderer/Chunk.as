/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.OxelPersistence;
import com.voxelengine.worldmodel.tasks.landscapetasks.GrowTreesOn;
import com.voxelengine.worldmodel.tasks.renderTasks.BuildFaces;

import flash.geom.Matrix3D;
import flash.display3D.Context3D;

import com.voxelengine.Log;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.renderTasks.BuildQuads;
import com.voxelengine.worldmodel.tasks.renderTasks.VisitorTask;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.oxel.GrainCursor;

public class Chunk {
	
	// You want this number to be as high as possible. 
	// But the higher it is, the longer updates take.
	//static private const MAX_CHILDREN:uint = 32768; // draw for all chunks on island takes 1ms
	//static private const MAX_CHILDREN:uint = 16384;
	//static private const MAX_CHILDREN:uint = 6000;
	static private const MAX_CHILDREN:uint = 8192;
	static public var _s_chunkCount:int;
	static public function chunkCount():int { return _s_chunkCount; }
	//static private const MAX_CHILDREN:uint = 4096; // draw for all chunks on island takes 5ms
	//static private const MAX_CHILDREN:uint = 2048;
	//static private const MAX_CHILDREN:uint = 1024;
	static private const OCT_TREE_SIZE:uint = 8;
	private var _children:Vector.<Chunk>; 	// These are created when needed
	private var _vertMan:VertexManager;
	private var _parent:Chunk;
	private var _guid:String;
	private var _bound:uint;

	private var _faceTasks:int;
	public function get faceTasks():int { return _faceTasks; }
	public function faceTasksReset():void { _faceTasks = 0; }
	public function faceTasksInc():void {
		_faceTasks++;
		if ( _parent )
			_parent.faceTasksInc()
	}
	public function faceTasksDec():void {
		_faceTasks--;
		if ( _parent )
			_parent.faceTasksDec();
	}

	private var _quadTasks:int;
	public function get quadTasks():int { return _quadTasks; }
	public function quadTasksReset():void { _quadTasks = 0; }
	public function quadTasksInc():void {
		_quadTasks++;
		if ( _parent )
			_parent.quadTasksInc();
	}

	public function quadTasksDec():void {
		_quadTasks--;
		if ( _parent )
			_parent.quadTasksDec();
	}

	private var _gc:GrainCursor; 			// Object that give us our location allocates memory for the grain
	public function get  gc():GrainCursor { return _gc; } 			// Object that give us our location allocates memory for the grain

	private var _lightInfo:LightInfo;
	public function get lightInfo():LightInfo { return _lightInfo; }

	private var _oxel:Oxel;
	public function get oxel():Oxel  { return _oxel; }

	private var _op:OxelPersistence;

	/*
	* There are TWO types of dirty!
	* The faces being dirty, and the vertex buffers being dirty
	 */
	private var _dirtyFacesOrQuads:Boolean;
	public function get dirtyFacesOrQuads():Boolean { return _dirtyFacesOrQuads; }
	public function set dirtyFacesOrQuads($val:Boolean):void {
		_dirtyFacesOrQuads = $val;
		if ( _parent && !_parent.dirtyFacesOrQuads )
			_parent.dirtyFacesOrQuads = $val;
	}

	private var _dirtyVertices:Boolean;
	public function get dirtyVertices():Boolean { return _dirtyVertices; }
	public function dirtyVertexsSet($type:int):void {
		_dirtyVertices = true;
		if ( _vertMan )
			_vertMan.VIBGet( $type ).dirty = true;
	}

	public function markToSendToGPU():void {
		if ( childrenHas() ) {
			for ( var i:int = 0; i < OCT_TREE_SIZE; i++ )
				_children[i].markToSendToGPU();
		}
		else {
			if ( _vertMan )
				_vertMan.markToSendToGPU();
		}
	}

	public function setAllVertexTypesDirty():void {
		_dirtyVertices = true;
		if ( childrenHas() ) {
			for ( var i:int = 0; i < OCT_TREE_SIZE; i++ )
				_children[i].setAllVertexTypesDirty();
		}
		else {
			if ( _vertMan )
				_vertMan.setAllTypesDirty();
		}
	}

	public function childrenHas():Boolean { return null != _children; }

	// TODO
	// add functions and optimize
	// I can see I need two more functions
	// public function merge():Chunk
	// public function divide():?
	public function Chunk( $op:OxelPersistence, $parent:Chunk, $bound:uint, $guid:String, $lightInfo:LightInfo ):void {
		_op = $op;
		_parent = $parent;
		_guid = $guid;
		_bound = $bound;
		_lightInfo = $lightInfo;

		_dirtyFacesOrQuads = true;
		_gc = GrainCursorPool.poolGet( _bound );
		_gc.grain = _bound;
		_s_chunkCount++;

		// when I create the chunk I add a light level to it.
		if ( 0 == _lightInfo.ID )
			Log.out( "Chunk - LIGHT ID IS ZERO lightInfo: " + _lightInfo, Log.WARN );
		//else
		//	Log.out( "Chunk - new chunk: " + $oxel.childCount + "  $lightInfo: " + $lightInfo, Log.WARN );
	}
	
	public function release():void {
		if ( childrenHas() ) {
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ ) {
				_children[i].release();
			}
		}
		else {
			if ( _vertMan )
				_vertMan.release();
			_vertMan = null;
			_oxel = null;
			_parent = null;
			_s_chunkCount--;
		}
		GrainCursorPool.poolDispose( _gc );
	}
	
	
	public function parse( $oxel:Oxel ):void {
		//var time:int = getTimer();

//		Log.out( "chunk.parse - creating children chunks: " + $oxel.childCount + " chunks in world - chunkCount: " + Chunk.chunkCount(), Log.WARN );
		if ( MAX_CHILDREN < $oxel.childCount ) {
			var gct:GrainCursor = GrainCursorPool.poolGet( _bound );
			//Log.out( "parse - creating children chunks: " + $oxel.childCount, Log.WARN );
			_children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ ) {
				var newChunk:Chunk = new Chunk( _op, this, _bound, _guid, _lightInfo );
				gct.copyFrom( _gc );
				gct.become_child( i );
				newChunk._gc.copyFrom( gct );
				newChunk.parse( $oxel.children[i] );
				_children[i] = newChunk;
				//Log.out( "chunk.parse - new child with chunk gc: " + _children[i]._gc + " count: " + (_children[i].oxel ? _children[i].oxel.childCount : "parent")  + " chunkCount: " + Chunk.chunkCount(), Log.WARN );
			}
			GrainCursorPool.poolDispose( gct );
		}
		else {
			//Log.out( "chunk.parse - creating chunk with child count: " + $oxel.childCount, Log.WARN );
			_oxel = $oxel;
			$oxel.chunk = this;
			if ( 1 == $oxel.childCount && false == $oxel.facesHas() ) {
				//Log.out( "chunk.parse --------------- EMPTY CHUNK, no faces" );
				dirtyFacesOrQuads = false;
			}
			else {
				//Log.out( "chunk.parse - new VertexManager: " + $oxel.childCount + "  oxel.gc: " + $oxel.gc, Log.WARN );
				_vertMan = new VertexManager( $oxel.gc, null );
			}
		}
		//Log.out( "Chunk.parse took: " + (getTimer() - time), Log.WARN );
	}

	public function drawNew( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {
		//trace( "Chunk.drawNew gc:" + gc);
		if ( childrenHas() ) {
			//trace( "Chunk.drawNew gc:" + gc + "  parent");
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNew( $mvp, $vm, $context, $selected, $isChild );
		}
		else if ( _vertMan ) // TODO optimize by marking if this node has content.
			//trace( "Chunk.drawNew gc:" + gc + "  vert " + _vertMan._vertBuf.totalOxels());
			_vertMan.drawNew( $mvp, $vm, $context, $selected, $isChild );
	}
	
	public function drawNewAlpha( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {		
		if ( childrenHas() ) {
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		}
		else if ( _vertMan )
			_vertMan.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
	}

	public function get isBuilding():Boolean {
		return faceTasks || quadTasks;
	}

	public function faceAndQuadsBuild( $buildFaces:Boolean, $forceFaces:Boolean = false, $forceQuads:Boolean = false ):void {
		//Log.out("--Chunk.faceAndQuadsBuild - guid: "  + _guid + " $buildFaces: " + $buildFaces + " forceFaces: " + $forceFaces + "  forceQuads: " + $forceQuads, Log.WARN);

		var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
		quadTasksReset();
		faceTasksReset();
		var priority:int;
		if ( ( $forceFaces || $forceQuads ) && vm )
			priority = vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		OxelDataEvent.addListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildTaskComplete );
		OxelDataEvent.addListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildTaskComplete );
		// did we add any tasks? if not, do clean up
		if ( !faceAndQuadsBuildRecursively( priority, $buildFaces, $forceFaces ,$forceQuads ) ) {
            // When would either of these happen? Answer: Trying to build a clean model
            // It is possible that there are NO face task or quad tasks, if so this sends the correct messages
            faceTaskCleanup();
            quadTaskCleanup();
        }
		//Log.out("--Chunk.faceAndQuadsBuild - EXIT guid: "  + _guid + " faceTasks: " + faceTasks + " quadTasks: " + quadTasks, Log.WARN);
	}

	// This function has acted strangely on 11.30.17, it was skipping past the chunk.dirtyFacesOrQuads even when true
	// so I broke it down into much smaller pieces and now it seems to work again...
	public function faceAndQuadsBuildRecursively( $priority:int, $buildFaces:Boolean, $forceFaces:Boolean = false, $forceQuads:Boolean = false  ):Boolean {
        _dirtyFacesOrQuads = false;
        var tasksAdded:Boolean = false;
        if (childrenHas()) {
            for (var i:int = 0; i < OCT_TREE_SIZE; i++) {
                var chunk:Chunk = _children[i];
                //Log.out( "Chunk.faceAndQuadsBuildRecursively - i: " + i + "  child chunk GC: " + chunk.gc );
                if ( $forceQuads || $forceFaces ) {
                    if ( true == chunk.dirtyFacesOrQuads ) {
                        var result:Boolean = chunk.faceAndQuadsBuildRecursively($priority, $buildFaces, $forceFaces, $forceQuads);
                        tasksAdded = tasksAdded || result;
                    }
//                    else {
//                        Log.out("Chunk.faceAndQuadsBuildRecursively - $forceQuads: " + $forceQuads + "  $forceFaces: " + $forceFaces + "  _children[i].dirtyFacesOrQuads: " + chunk);
//                    }
				}
//				else {
//                    Log.out("Chunk.faceAndQuadsBuildRecursively - $forceQuads: " + $forceQuads + "  $forceFaces: " + $forceFaces + "  _children[i].dirtyFacesOrQuads: " + chunk);
//                }
            }
        }
        else {
            if (_oxel) {
                // This adjusts the order so that the larger grains draw first.
                // This makes the overall object appear faster.
                var adjustedPriority:int = $priority - gc.grain;
                if (0 > adjustedPriority)
                    adjustedPriority = 1;
                if (( _oxel.dirty && $buildFaces ) || $forceFaces) {
                    //Log.out("--Chunk addFaceTask - guid: "  + _guid + " gc: " + gc + " buildFaces?: " + ( _oxel.dirty || $buildFaces ) + "  forceFaces: " + $forceFaces, Log.WARN);
                    addFaceTask(adjustedPriority, $forceFaces);
                    tasksAdded = true;
                }
//				else
//                    Log.out("--Chunk SKIPPING addFaceTask - guid: "  + _guid + " gc: " + gc + " _oxel.dirty: " + _oxel.dirty + " $buildFaces: " + $buildFaces + "  forceFaces: " + $forceFaces, Log.WARN);

                if (_oxel.dirty || $forceQuads) {
                    //Log.out("--Chunk addQuadTask - guid: "  + _guid + " gc: " + gc + " buildQuads?: " + ( _oxel.dirty || $forceQuads ) + "  forceFaces: " + $forceFaces, Log.WARN);
                    addQuadTask(adjustedPriority, $forceQuads);
                    tasksAdded = true;
                }
//                else
//                    Log.out("--Chunk SKIPPING addQuadTask - guid: "  + _guid + " gc: " + gc + " _oxel.dirty: " + _oxel.dirty + "  forceFaces: " + $forceQuads, Log.WARN);
            }
//			else
//            	Log.out("--Chunk SKIPPING CHUNK - guid: "  + _guid + " gc: " + gc + " NO OXEL", Log.WARN);
        }
        return tasksAdded;
    }

	private function addFaceTask( $priority:int, $forceFaces:Boolean ):void {
		faceTasksInc();
		BuildFaces.addTask( _guid, this, $priority, $forceFaces )
	}

	private function addQuadTask( $priority:int, $forceQuads:Boolean ):void {
		quadTasksInc();
		BuildQuads.addTask( _guid, this, $forceQuads, $priority )
	}

	private function facesBuildTaskComplete( $ode:OxelDataEvent ):void {
		//Log.out( "Chunk.facesBuildTaskComplete - Partial - guid: " + _guid + "  $ode.modelGuid: " + $ode.modelGuid, Log.WARN );
		if ( $ode.modelGuid == _guid ) {
			faceTasksDec();
            faceTaskCleanup();
		}
	}

    private function faceTaskCleanup():void {
        if (0 == faceTasks) {
            //Log.out("Chunk.facesBuildTaskComplete - COMPLETE - guid: " + _guid, Log.WARN);
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildTaskComplete);
            OxelDataEvent.create(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, _op);
        }
    }

	private function quadsBuildTaskComplete( $ode:OxelDataEvent ):void {
		//Log.out( "Chunk.quadsBuildTaskComplete - Partial - guid: " + _guid + "  $ode.modelGuid: " + $ode.modelGuid, Log.WARN );
		if ( $ode.modelGuid == _guid ) {
			quadTasksDec();
			quadTaskCleanup();
		}
	}

    private function quadTaskCleanup():void {
        if (0 == quadTasks) {
            //Log.out("Chunk.quadsBuildTaskComplete - ALL TASKS COMPLETE - guid: " + _guid, Log.WARN);
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildTaskComplete);
            OxelDataEvent.create(OxelDataEvent.OXEL_BUILD_COMPLETE, 0, _guid, _op);
        }
    }

	public function visitor( $guid:String, $func:Function, $functionName:String = "" ):void {
		if ( childrenHas() ) {
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ )
				_children[i].visitor( $guid, $func, $functionName );
		}
		else if ( _vertMan )
			VisitorTask.addTask( $guid, this, $func, 10000, $functionName )
	}

    // Similar to visitor task, but requires guid
    public function buildTrees( $chance:int ):void {
        if ( childrenHas() ) {
            for ( var i:int=0; i < OCT_TREE_SIZE; i++ ) {
                _children[i].buildTrees( $chance );
            }
        }
        else {
            if ( _oxel )
                GrowTreesOn.addTask( _guid, this, $chance );
        }
    }

	public function oxelRemove( $oxel:Oxel ):void {
		if ( _vertMan )
			_vertMan.oxelRemove( $oxel );
	}

	public function oxelAdd( $oxel:Oxel ):void {
		if ( !_vertMan )
			_vertMan = new VertexManager( $oxel.gc, null );

		if ( !$oxel.facesHas() )
			return;

		_vertMan.oxelAdd( $oxel );
	}

}
}
