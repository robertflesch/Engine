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
			Log.out( "chunk.parse - LIGHT ID IS ZERO lightInfo: " + _lightInfo, Log.WARN );
		//else
		//	Log.out( "chunk.parse - new chunk: " + $oxel.childCount + "  $lightInfo: " + $lightInfo, Log.WARN );
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

		//Log.out( "chunk.parse - creating children chunks: " + $oxel.childCount + " chunkCount: " + Chunk.chunkCount(), Log.WARN );
		if ( MAX_CHILDREN < $oxel.childCount ) {
			var gct:GrainCursor = GrainCursorPool.poolGet( _bound );
			//Log.out( "parse - creating children chunks: " + $oxel.childCount, Log.WARN );
			_children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ ) {
				var newChunk:Chunk = new Chunk( _op, this, _bound, _guid, _lightInfo );
				_children[i] = newChunk.parse( $oxel.children[i] );
				gct.copyFrom( _gc );
				gct.become_child( i );
				_children[i]._gc.copyFrom( gct );
				//Log.out( "chunk.parse - chunk gc: " + _children[i]._gc + " count: " + (_children[i].oxel ? _children[i].oxel.childCount : "parent")  + " chunkCount: " + Chunk.chunkCount(), Log.WARN );
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
/*
	public function quadsBuild( $forceAll:Boolean = false ):void {
		var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
		_quadTasks = 0;
		var priority:int;
		if ( $forceAll && vm )
			priority = vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		OxelDataEvent.addListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
		quadsBuildDirtyRecursively( _guid, priority, $forceAll );
		if ( 0 == _quadTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	private function quadsBuildDirtyRecursively( $guid:String, $priority:int, $forceAll:Boolean ):void {
		_dirtyFacesOrQuads = false;
		if ( childrenHas() ) {
			for ( var i:int = 0; i < OCT_TREE_SIZE; i++ ) {
				if ( $forceAll || _children[i].dirtyFacesOrQuads )
					_children[i].quadsBuildDirtyRecursively( $guid, $priority, $forceAll );
			}
		} else {
			if ( _oxel )
				addQuadTask( $priority, $forceAll );
			else
				Log.out( "Chunk.buildQuadsRecursively - HOW DID I GET HERE?", Log.WARN);
		}
	}
*/
	/*
	public function buildFaces( $firstTime:Boolean = false ):void {
		var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
		_faceTasks = 0;
		var priority:int;
		if ( $firstTime && vm )
			priority = vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		OxelDataEvent.addListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildPartialComplete );
		buildFacesRecursively( _guid, priority, $firstTime );
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
*/
	private var _faceTasks:int;
	private var _quadTasks:int;
	public function faceAndQuadsBuild( $forceFaces:Boolean = false, $forceQuads:Boolean = false ):void {
		var vm:VoxelModel = Region.currentRegion.modelCache.getModelFromModelGuid( _guid );
		_quadTasks = 0;
		_faceTasks = 0;
		var priority:int;
		if ( ( $forceFaces || $forceQuads ) && vm )
			priority = vm.distanceFromPlayerToModel(); // This should really be done on a per chuck basis
		else
			priority = 100; // high but not too high?
		faceAndQuadsBuildRecursively( priority, $forceFaces ,$forceQuads );
		if ( 0 == _quadTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	public function faceAndQuadsBuildRecursively( $priority:int, $forceFaces:Boolean = false, $forceQuads:Boolean = false  ):void {
		_dirtyFacesOrQuads = false;
		if ( childrenHas() ) {
			for ( var i:int=0; i < OCT_TREE_SIZE; i++ ) {
				if ( _children[i].dirtyFacesOrQuads || $forceFaces || $forceQuads )
					_children[i].faceAndQuadsBuildRecursively( $priority, $forceFaces, $forceQuads );
			}
		}
		else {
			if ( _oxel && ( _oxel.dirty || $forceFaces || $forceQuads ) ) {
				if ( _oxel.dirty || $forceFaces )
					addFaceTask( $priority, $forceFaces );
				addQuadTask( $priority, $forceQuads );
			}
		}
	}

	private function addFaceTask( $priority:int, $forceFaces:Boolean ):void {
		_faceTasks++;
		BuildFaces.addTask( _guid, this, $priority, $forceFaces )
	}

	private function addQuadTask( $priority:int, $forceQuads:Boolean ):void {
		_quadTasks++;
		BuildQuads.addTask( _guid, this, $forceQuads, $priority )
	}

	private function quadsBuildPartialComplete( $ode:OxelDataEvent ):void {
		_quadTasks--;
		if ( 0 == _quadTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_PARTIAL, quadsBuildPartialComplete );
			OxelDataEvent.create(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, 0, _guid, null);
		}
	}

	private function facesBuildPartialComplete( $ode:OxelDataEvent ):void {
		_faceTasks--;
		if ( 0 == _faceTasks) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FACES_BUILT_PARTIAL, facesBuildPartialComplete );
			OxelDataEvent.create( OxelDataEvent.OXEL_FACES_BUILT_COMPLETE, 0, _guid, null );
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
