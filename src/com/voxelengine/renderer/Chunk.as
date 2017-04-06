/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.pools.ChildOxelPool;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.GrainCursor;

import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.utils.getTimer;

import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.renderTasks.BuildQuads;
import com.voxelengine.worldmodel.tasks.renderTasks.RefreshFaces;
import com.voxelengine.worldmodel.tasks.renderTasks.VisitorTask;

public class Chunk {
	
	// You want this number to be as high as possible. 
	// But the higher it is, the longer updates take.
	//static private const MAX_CHILDREN:uint = 32768; // draw for all chunks on island takes 1ms
	//static private const MAX_CHILDREN:uint = 16384;
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

	private var _gc:GrainCursor; 			// Object that give us our location allocates memory for the grain
	public function get  gc():GrainCursor { return _gc }; 			// Object that give us our location allocates memory for the grain

	private var _lightInfo:LightInfo;
	public function get lightInfo():LightInfo { return _lightInfo; }

	private var _oxel:Oxel;
	public function get oxel():Oxel  { return _oxel; }
	
	// TODO Should just add dirty chunks to a rebuild queue, which would get me a more incremental build
	private var _dirty:Boolean;
	public function get dirty():Boolean { return _dirty; }
	public function dirtyClear():void { _dirty = false; }
	public function dirtySet( $type:uint ):void {
		_dirty = true;
		if ( _parent && !_parent.dirty ) 
			_parent.dirtySet( $type );
			
		if ( _vertMan )			
			_vertMan.VIBGet( $type ).dirty = true;
	}
	public function childrenHas():Boolean { return null != _children; }
	
	public function Chunk( $parent:Chunk, $bound:uint, $guid ):void {
		_parent = $parent;
		_guid = $guid;
		_dirty = true;
		_gc = GrainCursorPool.poolGet( $bound );
		_s_chunkCount++;
	}
	
	public function release():void {
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				_children[i].release();
			}
		}
		else {
			_vertMan.release();
			_oxel = null;
			_parent = null;
			_s_chunkCount--;
		}
		GrainCursorPool.poolDispose( _gc );
	}
	
	
	// TODO
	// add functions and optimize
	// I can see I need two more functions
	// public function merge():Chunk
	// public function divide():?
	
	static public function parse( $oxel:Oxel, $parent:Chunk, $lightInfo:LightInfo, $guid:String ):Chunk {
		var time:int = getTimer();
		var bound:uint = $oxel.gc.bound;
		var chunk:Chunk = new Chunk( $parent, bound, $guid );

		chunk._gc.grain = $parent ? ($parent._gc.grain - 1) : $oxel.gc.bound;

		// when I create the chunk I add a light level to it.
		if ( 0 == $lightInfo.ID )
			Log.out( "chunk.parse - LIGHT ID IS ZERO lightInfo: " + $lightInfo, Log.WARN );
		//else
		//	Log.out( "chunk.parse - new chunk: " + $oxel.childCount + "  $lightInfo: " + $lightInfo, Log.WARN );
		chunk._lightInfo = $lightInfo;

		//Log.out( "chunk.parse - creating children chunks: " + $oxel.childCount + " chunkCount: " + Chunk.chunkCount(), Log.WARN );
		if ( MAX_CHILDREN < $oxel.childCount ) {
			var gct:GrainCursor = GrainCursorPool.poolGet( chunk._gc.bound );
			//Log.out( "chunk.parse - creating children chunks: " + $oxel.childCount, Log.WARN );
			chunk._children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				chunk._children[i] = parse($oxel.children[i], chunk, $lightInfo, chunk._guid );
				gct.copyFrom( chunk._gc );
				gct.become_child( i );
				chunk._children[i]._gc.copyFrom( gct );
				//Log.out( "chunk.parse - chunk gc: " + chunk._children[i]._gc + " count: " + (chunk._children[i].oxel ? chunk._children[i].oxel.childCount : "parent")  + " chunkCount: " + Chunk.chunkCount(), Log.WARN );
			}
			GrainCursorPool.poolDispose( gct );
		}
		else {
			//Log.out( "chunk.parse - creating chunk with child count: " + $oxel.childCount, Log.WARN );
			chunk._oxel = $oxel;
			$oxel.chunk = chunk;
			if ( 1 == $oxel.childCount && false == $oxel.facesHas() ) {
				//Log.out( "chunk.parse --------------- EMPTY CHUNK, no faces" );
				chunk.dirtyClear();
			}
			else {
				//Log.out( "chunk.parse - new VertexManager: " + $oxel.childCount + "  oxel.gc: " + $oxel.gc, Log.WARN );
				chunk._vertMan = new VertexManager( $oxel.gc, null );
			}
		}
		//Log.out( "Chunk.parse took: " + (getTimer() - time), Log.WARN );
		return chunk;
	}

	public function drawNew( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNew( $mvp, $vm, $context, $selected, $isChild );
		}
		else if ( _vertMan )
			_vertMan.drawNew( $mvp, $vm, $context, $selected, $isChild );
	}
	
	public function drawNewAlpha( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {		
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		}
		else if ( _vertMan )
			_vertMan.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
	}

	private var _quadTasks:int;
	public function buildQuads( $guid:String, $vm:VoxelModel, $firstTime:Boolean = false ):void {
		_quadTasks = 0;
		var priority:int;
		if ( $firstTime && $vm )
			priority = $vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		OxelDataEvent.addListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
		buildQuadsRecursively( $guid, priority, $firstTime );
		if ( 0 == _quadTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	private function buildQuadsRecursively( $guid:String, $priority:int, $firstTime:Boolean = false ):void {
		if ( childrenHas() ) {
			dirtyClear();
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				//if ( _children[i].dirty && _children[i]._oxel && _children[i]._oxel.dirty )
				if ( _children[i].dirty )
					_children[i].buildQuadsRecursively( $guid, $priority, $firstTime );
			}
		} else {
			// Since task has been added for this chunk, mark it as clear
			// NOTE: oxels loaded from NoSQL are not dirty. But need to be built
			//if ( _oxel && _oxel.dirty ) {
			if ( _oxel ) {
				dirtyClear();
				_quadTasks++;
				BuildQuads.addTask( $guid, this, $priority )
			}
			else {
				Log.out( "Chunk.buildQuadsRecursively - HOW DID I GET HERE?", Log.WARN);
				dirtyClear(); // Better clear it anyways
			}
		}
	}

	private function quadsBuildPartialComplete( $ode:OxelDataEvent ):void {
		_quadTasks--;
		if ( 0 == _quadTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	private var _faceTasks:int;
	public function buildFaces( $guid:String, $vm:VoxelModel, $firstTime:Boolean = false ):void {
		_faceTasks = 0;
		var priority:int;
		if ( $firstTime && $vm )
			priority = $vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		OxelDataEvent.addListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildPartialComplete );
		buildFacesRecursively( $guid, priority, $firstTime );
		if ( 0 == _faceTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	private function buildFacesRecursively( $guid:String, $priority:int, $firstTime:Boolean = false ):void {
		if ( childrenHas() ) {
			dirtyClear();
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				//if ( _children[i].dirty && _children[i]._oxel && _children[i]._oxel.dirty )
				if ( _children[i].dirty )
					_children[i].buildFacesRecursively( $guid, $priority, $firstTime );
			}
		}
		else {
			// Since task has been added for this chunk, mark it as clear
			dirtyClear();
			if ( _oxel && _oxel.dirty ) {
				_faceTasks++;
				RefreshFaces.addTask( $guid, this, $priority );
			}
		}
	}

	private function facesBuildPartialComplete( $ode:OxelDataEvent ):void {
		_faceTasks--;
		if ( 0 == _faceTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildPartialComplete );
			OxelDataEvent.create( OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, null );
		}
	}

	public function setDirtyRecursively():void {
		if ( childrenHas() ) {
			_dirty = true;
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].setDirtyRecursively();
		} else {
			_dirty = true;
			if ( _oxel )
				_oxel.setDirtyRecursively();
		}
	}

	public function visitor( $guid:String, $func:Function, $functionName:String = "" ):void {
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].visitor( $guid, $func, $functionName );
		}
		else if ( _vertMan )
			VisitorTask.addTask( $guid, this, $func, 10000, $functionName )
		
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
