/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import com.voxelengine.worldmodel.TypeInfo;
import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.utils.getTimer;
import flash.utils.Timer;
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class Chunk {
	
	static private const MAX_CHILDREN:uint = 4096;
	//static private const MAX_CHILDREN:uint = 2048;
	static private const OCT_TREE_SIZE:uint = 8;
	private var _children:Vector.<Chunk>; 	// These are created when needed
	private var _vertMan:VertexManager
	private var _oxel:Oxel;
	private var _dirty:Boolean;
	private var _parent:Chunk;
	
	public function get dirty():Boolean { return _dirty; }
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
		}
	}
	
	
	// TODO
	// add functions and optimize
	//
	// I can see I need two more functions
	// public function merge():Chunk
	// public function divide():?
	
	static public function parse( $oxel:Oxel, $parent:Chunk ):Chunk {
		var chunk:Chunk = new Chunk( $parent );
		//Log.out( "chunk.parse - new chunk: " + $oxel.childCount );
			
		if ( MAX_CHILDREN < $oxel.childCount ) {
			chunk._children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				chunk._children[i] = parse( $oxel.children[i], chunk );
		}
		else {
			chunk._oxel = $oxel;
			$oxel.chunk = chunk;
			if ( 1 == $oxel.childCount && false == $oxel.facesHas() ) {
				//Log.out( "chunk.parse - EMPTY CHUNK, no faces" );
				chunk.dirtyClear();
			}
			else {
				//Log.out( "chunk.parse - new VertexManager: " + $oxel.childCount + "  oxel.gc: " + $oxel.gc );
				chunk._vertMan = new VertexManager( $oxel.gc, null );
			}
		}
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
	
	public function  refreshFaces():void {
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				if ( _children[i].dirty )
					_children[i].refreshFaces();
			}
		}
		else {
			_oxel.facesBuild();
		}
	}

	public function refreshQuads():void {
		if ( childrenHas() ) {
			dirtyClear();
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				if ( _children[i].dirty )
					_children[i].refreshQuads();
			}
		}
		else {
			_oxel.quadsBuild();
			dirtyClear();
		}
	}
	
	public function oxelRemove( $oxel:Oxel ):void {
		if ( _vertMan )
			_vertMan.oxelRemove( $oxel );
	}

	public function oxelAdd( $oxel:Oxel ):void {
		if ( !_vertMan )
			_vertMan = new VertexManager( $oxel.gc, null );
		
		_vertMan.oxelAdd( $oxel );
	}
	
}
}
