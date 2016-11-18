/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import com.voxelengine.pools.LightingPool;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Lighting;

import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.utils.getTimer;
import flash.utils.Timer;
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.renderTasks.RefreshQuadsAndFaces;
import com.voxelengine.worldmodel.tasks.renderTasks.VistorTask;

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
	private var _vertMan:VertexManager
	private var _oxel:Oxel;
	private var _dirty:Boolean;
	private var _parent:Chunk;
	private var _lightInfo:LightInfo;

	public function get lightInfo():LightInfo { return _lightInfo; }
	public function get dirty():Boolean { return _dirty; }
	public function get oxel():Oxel  { return _oxel; }
	
	// TODO Should just add dirty chunks to a rebuild queue, which would get me a more incremental build
	public function dirtyClear():void { _dirty = false; }
	public function dirtySet( $type:uint ):void {
		_dirty = true;
		if ( _parent && !_parent.dirty ) 
			_parent.dirtySet( $type );
			
		if ( _vertMan )			
			_vertMan.VIBGet( $type ).dirty = true;
	}
	public function childrenHas():Boolean { return null != _children; }
	
	public function Chunk( $parent:Chunk ):void {
		_parent = $parent;
		_dirty = true;
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
	}
	
	
	// TODO
	// add functions and optimize
	//
	// I can see I need two more functions
	// public function merge():Chunk
	// public function divide():?
	
	static public function parse( $oxel:Oxel, $parent:Chunk, $lightInfo:LightInfo ):Chunk {
		var time:int = getTimer();

		var chunk:Chunk = new Chunk( $parent );
		// when I create the chunk I add a light level to it.

		//Log.out( "chunk.parse - new chunk: " + $oxel.childCount, Log.WARN );
		chunk._lightInfo = $lightInfo;
			
		if ( MAX_CHILDREN < $oxel.childCount ) {
			//Log.out( "chunk.parse - creating parent chunk: " + $oxel.childCount, Log.WARN );
			chunk._children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				chunk._children[i] = parse( $oxel.children[i], chunk, $lightInfo );
		}
		else {
			//Log.out( "chunk.parse - creating chunk with child count: " + $oxel.childCount, Log.WARN );
			chunk._oxel = $oxel;
			$oxel.chunk = chunk;
			if ( 1 == $oxel.childCount && false == $oxel.facesHas() ) {
				//Log.out( "chunk.parse - EMPTY CHUNK, no faces" );
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
	
	public function refreshFacesTerminal():void {
		_oxel.facesBuild();
	}

	public function rebuildLighting():void {
		//public function refreshFacesAndQuadsTerminal():void {
		if ( childrenHas() ) {
			for (var i:int; i < OCT_TREE_SIZE; i++)
				_children[i].rebuildLighting();
		}
		else {
			if ( _oxel && _oxel.childrenHas() ) {

			}
			else
				refreshFacesAndQuadsTerminal()
		}
	}
	
	public function refreshFacesAndQuads( $guid:String, $vm:VoxelModel, $firstTime:Boolean = false ):void {
		if ( childrenHas() ) {
			dirtyClear();
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				//if ( _children[i].dirty && _children[i]._oxel && _children[i]._oxel.dirty )
				if ( _children[i].dirty )
					_children[i].refreshFacesAndQuads( $guid, $vm, $firstTime );
			}
		}
		else {
			// Since task has been added for this chunk, mark it as clear
			dirtyClear();
			if ( _oxel && _oxel.dirty ) {
//				if ( $firstTime ) {
//					var priority:int = $vm.distanceFromPlayerToModel();
//					RefreshQuadsAndFaces.addTask( $guid, this, priority )
//				}
//				else
//					refreshFacesAndQuadsTerminal()
				var priority:int;
				if ( $firstTime )
					 priority = $vm.distanceFromPlayerToModel();
				else
					priority = 4; // high but not too high?

				RefreshQuadsAndFaces.addTask( $guid, this, priority )
			}
		}
	}
	
	public function visitor( $guid:String, $func:Function ):void {
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].visitor( $guid, $func );
		}
		else if ( _vertMan )
			VistorTask.addTask( $guid, this, $func, 10000 )
		
	}

	public function refreshFacesAndQuadsTerminal():void {
		_oxel.facesBuild()
		_oxel.quadsBuild()
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
