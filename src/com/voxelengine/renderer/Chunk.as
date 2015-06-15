/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.utils.getTimer;
import flash.utils.Timer;
	
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class Chunk {
	
	//static private const MAX_CHILDREN:uint = 4096;
	static private const MAX_CHILDREN:uint = 2048;
	static private const OCT_TREE_SIZE:uint = 8;
	private var _children:Vector.<Chunk>; 	// These are created when needed
	private var _vertMan:VertexManager
	private var _oxel:Oxel;
	private var _dirty:Boolean;
	private var _parent:Chunk;
	
	public function get dirty():Boolean { return _dirty; }
	// TODO Should just add dirty chunks to a rebuild queue, which would get me a more incremental build
	public function set dirty($value:Boolean):void {
//		if ( _vertMan )
//			Log.out( "chunk.dirty - marking chunk dirty: " + _oxel.gc + "  dirty: " + $value );
		_dirty = $value;
		if ( _parent && !_parent.dirty ) 
			_parent.dirty = $value;
	}
	public function childrenHas():Boolean { return null != _children; }
	
	public function Chunk( $parent:Chunk ):void {
		_parent = $parent;
		_dirty = true;
	}
	
	// I can see I need two more functions
	// public function merge():Chunk
	// public function divide():?
	
	static public function parse( $oxel:Oxel, $parent:Chunk ):Chunk {
		var ch:Chunk = new Chunk( $parent );
		Log.out( "chunk.parse - new chunk: " + $oxel.childCount );
		if ( MAX_CHILDREN < $oxel.childCount ) {
			ch._children = new Vector.<Chunk>(OCT_TREE_SIZE, true);
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				ch._children[i] = parse( $oxel.children[i], ch );
		}
		else {
			ch._oxel = $oxel;
			Log.out( "chunk.parse - new VertexManager: " + $oxel.childCount + "  oxel.gc: " + $oxel.gc );
			$oxel.chunk = ch;
			ch._vertMan = new VertexManager( $oxel.gc, null );
		}
		return ch;	
	}
	
	public function drawNew( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {		
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNew( $mvp, $vm, $context, $selected, $isChild );
		}
		else
			_vertMan.drawNew( $mvp, $vm, $context, $selected, $isChild );
	}
	
	public function drawNewAlpha( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {		
		if ( childrenHas() ) {
			for ( var i:int; i < OCT_TREE_SIZE; i++ )
				_children[i].drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		}
		else
			_vertMan.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
	}
	
	public function refreshQuads():void {
		if ( childrenHas() ) {
			dirty = false;
			for ( var i:int; i < OCT_TREE_SIZE; i++ ) {
				if ( _children[i].dirty )
					_children[i].refreshQuads();
			}
		}
		else {
			_oxel.quadsBuild();
			dirty = false;
		}
	}
	
	public function oxelRemove( $oxel:Oxel, $type:int ):void {
		_vertMan.oxelRemove( $oxel, $type );
	}

	public function oxelAdd( $oxel:Oxel ):void {
		_vertMan.oxelAdd( $oxel );
	}
	
}
}
