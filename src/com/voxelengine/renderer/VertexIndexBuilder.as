/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import flash.display3D.VertexBuffer3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.utils.getTimer;
import flash.utils.ByteArray;
import flash.utils.Endian;

import com.voxelengine.Log;
import com.voxelengine.pools.VertexIndexBuilderPool;
import com.voxelengine.renderer.vertexComponents.VertexComponent;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;


public class VertexIndexBuilder
{
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Static Variables
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private static var _s_totalVertexMemory:int = 0;
	private static var _s_totalIndexMemory:int = 0;
	private static var _s_totalUsed:int = 0;
	private static var _s_totalOxels:int = 0;

	private static const BUFFER_LIMIT:int = 65535;
	private static const BYTES_PER_WORD:uint = 4;
	private static const MAX_QUADS:int = (BUFFER_LIMIT + 1) / 4; // Buffer limit is max number of vertexes, and each quad has 4
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Static Functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// These are not getters because I am not able to access them from GUI if they are.
	public static function totalVertexMemory():int { return _s_totalVertexMemory/1000 ;}
	public static function totalIndexMemory():int { return _s_totalIndexMemory/1000 ; }
	public static function totalUsed():int { return _s_totalUsed; }
	public static function totalOxels():int { return _s_totalOxels;}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Member Variables
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private var _buffers:int = 0;
	private var _bufferVertexMemory:int = 0;
	private var _bufferIndexMemory:int = 0;
	private var _vertexBuffers:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>();
	private var _indexBuffers:Vector.<IndexBuffer3D> = new Vector.<IndexBuffer3D>();
	private var _oxels:Vector.<Oxel>;
	private var _vc:Vector.<VertexComponent> = new Vector.<VertexComponent>(Quad.COMPONENT_COUNT,true);
	private var _verticeByteArray:ByteArray = new ByteArray();
	private var _vertexDataSize:uint;
	
	private var _dirty:Boolean = false;

	private var _sortCount:int;
	private var _sortEvery:int;
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Getters/Setters
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function get dirty():Boolean { return _dirty; }
	public function set dirty( val:Boolean ):void { _dirty = val; }

	private var _sentToGPU:Boolean;
	public function get sentToGPU():Boolean { return _sentToGPU; }
	public function set sentToGPU( val:Boolean ):void { _sentToGPU = val; }

	
	public function get length():int { return _oxels ? _oxels.length : 0; }
	public function get hasFaces():Boolean { return 0 < _bufferVertexMemory; }
	
	public function VertexIndexBuilder()
	{
		_sortEvery = 45 + int( Math.random() * 30 );
	}

	public function release():void
	{
		dispose();
		if ( _oxels )
			_oxels.length = 0;
	}
	
	static private var _s_compareVec:Vector3D;
	static private function compareFunction( x:Oxel, y:Oxel ):int {
		if ( !x.gc )
			return 1;
		if ( !y.gc )
			return -1;

		// this could be speed up for sure	
		var xdist:Number = x.getDistance( _s_compareVec );
		var ydist:Number = y.getDistance( _s_compareVec );
		
		if ( xdist == ydist ) return 0;
		if ( xdist < ydist ) return -1;
		return 1;
	}
	
	public function sort() : void {
		//_sortCount++; // SORT DISABLED
		if ( _sortCount < _sortEvery )
			return;
			
		var timer:int = getTimer();

		if ( _oxels && 0 < _oxels.length ) {
			// this causes a major bottleneck if done each frame.
			// AND it doesnt work correctly
			_s_compareVec = VoxelModel.controlledModel.modelToWorld( VoxelModel.controlledModel.cameraContainer.current.position );
			//Log.out( "VertexIndexBuilder.sort - VoxelModel.controlledModel.modelToWorld: " + VoxelModel.controlledModel.modelToWorld( new Vector3D( 8, 8, 8) ) )
			//Log.out( "VertexIndexBuilder.sort - camera.center: " + VoxelModel.controlledModel.camera.center )
			//Log.out( "VertexIndexBuilder.sort - _s_compareVec: " + _s_compareVec );
			_oxels.sort( compareFunction );	
			trace( "VertexIndexBuilder - sorted: " + _oxels.length + " - took: "  + (getTimer() - timer) );					
		}
		_sortCount = 0;
	}

//	public static function resetStatics():void {
//		_s_totalVertexMemory = 0;
//		_s_totalIndexMemory = 0;
//	}
	
	public function print():void {
		for each ( var oxel:Oxel in _oxels ) 
		{
			for each ( var quad:Quad in oxel.quads )
				quad.print();
		}
	}

	public function oxelAdd( oxel:Oxel ):void {
		dirty = true;
		
		if ( !_oxels )
			_oxels = new Vector.<Oxel>();
		_oxels.push( oxel );
		_s_totalOxels++;
		//trace( "VertexIndexBuilder.addOxel - total oxels - " + _oxels.length + " quad_count: " + quad_count );
	}

	public function oxelRemove( oxel:Oxel ):void {
		dirty = true;

		if ( _oxels )
		{
			for ( var index:int = 0; index < _oxels.length; index++ )
			{
				if ( oxel == _oxels[index] ) {
					_oxels.splice( index, 1 );
					_s_totalOxels--;
					return;
				}
			}
			Log.out( "VertexIndexBuilder.oxelRemove - OXEL NOT FOUND - total oxels - " + _oxels.length + "  oxel: " + oxel.toString(), Log.WARN );
		}
	}
	
	public function dispose(): void {
		
 		while (_vertexBuffers.length > 0) {
			_vertexBuffers.pop().dispose();
			_s_totalUsed--;
		}
		_vertexBuffers.length = 0;
		while (_indexBuffers.length > 0) {
			_indexBuffers.pop().dispose();
		}
		_indexBuffers.length = 0;
		_s_totalVertexMemory  -= _bufferVertexMemory;
		_s_totalIndexMemory -= _bufferIndexMemory;
		
		_buffers = 0;
		_bufferVertexMemory = 0;
		_bufferIndexMemory = 0;
	
		dirty = true;
		
		//trace ( "VertexIndexBuilder - dispose" + this );			
	}

	// We need to break the quads in ~ 16k sized chunks. since that is the limit for each VertexBuffer
	public function buffersBuildFromOxels( context:Context3D ):Boolean {
		if ( !dirty || !_oxels )
		{
			//trace( "VertexIndexBuilder.buffersBuildFromOxels - CLEAN" );
			return false;
		}

		//trace( "VertexIndexBuilder.buffersBuildFromOxels - DIRTY" );
//		var time:int = getTimer();
		dispose();
		if ( 0 < _oxels.length )
		{
			var oxelStartingIndex:int = 0;
			var remainingOxels:int = _oxels.length;
			var quadsInOxel:int = 0;
			
			if ( 0 < remainingOxels )
				addComponentData();
			
			while ( 0 < remainingOxels ) {
				var quadsProcessed:int = 0;
				for ( var oxelsProcessed:int = oxelStartingIndex; oxelsProcessed < _oxels.length; oxelsProcessed++ ) 
				{
					// safety check on bad data
					if ( _oxels[oxelsProcessed].quads ) {
						quadsInOxel = _oxels[oxelsProcessed].quads.length;
						// Only process full oxels, if adding additional oxel will put us 
						// over limit, then don't include it
						if ( quadsProcessed + quadsInOxel <= MAX_QUADS )
							quadsProcessed += quadsInOxel;
						else
							break;
					}
					else	
						quadsInOxel = 0;
				}
				if ( 0 < oxelsProcessed - oxelStartingIndex )
					populateVertexAndIndexBuffers( oxelStartingIndex, oxelsProcessed - oxelStartingIndex , quadsProcessed, context );

				oxelStartingIndex = oxelsProcessed;
				remainingOxels = _oxels.length - oxelsProcessed;
				//trace( "VertexIndexBuilder.buffersBuildFromOxels oxelStartingIndex: " + oxelStartingIndex + " oxelsProcessed: " + oxelsProcessed + " quadsProcessed: " + quadsProcessed );
			}
		}
		
		_s_totalVertexMemory += _bufferVertexMemory;
		_s_totalIndexMemory += _bufferIndexMemory;

		dirty = false;
//		trace( "VertexIndexBuilder.buffersBuildFromOxels took: " + (getTimer()-time)+ " for " + _oxels.length + " oxels quads: " + quadsProcessed );
		return true
	}
	
	private function populateVertexAndIndexBuffers( $oxelStartingIndex:int, $oxelsToProcess:int, $quadsToProcess:int, $context:Context3D ):void {
		_s_totalUsed++;
		_bufferVertexMemory += $quadsToProcess * Quad.VERTEX_PER_QUAD * _vertexDataSize * BYTES_PER_WORD;
		
		_verticeByteArray.position = 0;
		_verticeByteArray.endian = Endian.LITTLE_ENDIAN;
		// NEW 2
		var _offsetIndices:Vector.<uint> = new Vector.<uint>( $quadsToProcess * Quad.INDICES );

		var i:uint=0;
		var oxel:Oxel;
		var quad:Quad;
		var quadCount:uint=0;
		var indice:uint;
		for ( var index:int = $oxelStartingIndex; index < $oxelStartingIndex + $oxelsToProcess; index++ ) {
			oxel = _oxels[index];
			if ( oxel.quads ) 
			{
				for each ( quad in oxel.quads ) 
				{
					if ( quad )
					{
						quadCount++;
						for each ( var vc:VertexComponent in quad.components ) {
							vc.writeToByteArray( _verticeByteArray );
						}
						// each indice has to be offset to have a unique offset
						for each ( indice in quad._indices ) {
							_offsetIndices[i] = int(i / 6) * 4 + indice;
							i++
						}
					}
				}
			}
		}
		try {
			var vb:VertexBuffer3D = $context.createVertexBuffer( quadCount * Quad.VERTEX_PER_QUAD, _vertexDataSize );
		} catch (error:ArgumentError) {
			Log.out('VertexIndexBuilder.quadsCopyToVertexBuffersByteArray - An argument error has occurred', Log.ERROR);
			return;
		} catch (error:Error) {
			Log.out('VertexIndexBuilder.quadsCopyToVertexBuffersByteArray - An error has occurred which is not argument related', Log.ERROR );
			return;
		}
		if ( null == vb ) {
			Log.out("VertexIndexBuilder.quadsCopyToVertexBuffersByteArray - Ran out of VertexBuffers total used: " + VertexIndexBuilderPool.totalUsed(), Log.ERROR );
			return;
		}
		vb.uploadFromByteArray ( _verticeByteArray, 0, 0, quadCount * Quad.VERTEX_PER_QUAD);
		_vertexBuffers.push(vb);
		_buffers++;
		
		_bufferIndexMemory = $quadsToProcess * Quad.INDICES;
		var ib:IndexBuffer3D = $context.createIndexBuffer( $quadsToProcess * Quad.INDICES );
		ib.uploadFromVector( _offsetIndices, 0, $quadsToProcess * Quad.INDICES );
		_indexBuffers.push(ib);
	}

	private function addComponentData():void {
		_vertexDataSize = 0;
		var oxelSize:int = _oxels.length;
		var oxel:Oxel;
		var quad:Quad;
		var indexQuad:int;
		var i:uint;
		//for each ( var oxel:Oxel in _oxels ) { // This is a slower way
		for ( var index:int=0; index < oxelSize; index++ ) {
		    oxel = _oxels[index];
			if ( oxel.quads ) {
				for ( indexQuad=0; indexQuad < oxel.quads.length; indexQuad++ ) {
					quad = oxel.quads[indexQuad];
					if ( quad && 0 < quad.components.length ) {
						for ( i=0; i < Quad.COMPONENT_COUNT; i++ ) {
							_vc[i] = quad.components[i];
							_vertexDataSize += quad.components[i].size;
						}
						return;
					}
				}
			}
		}
		Log.out( "VertexIndexBuilder.addComponentData - No components found", Log.WARN );
	}
	
	public function bufferCopyToGPU(context:Context3D ) : void {
//		if ( true == sentToGPU )
//			return;
//		sentToGPU = true;

		var vb:VertexBuffer3D;
		//var timer:int = getTimer();
		for (var i:int = 0; i < _buffers; i++) {
			vb = _vertexBuffers[i];
			var offset:uint = 0;
			for ( var index:uint = 0; index < _vc.length; index++ ) {
				context.setVertexBufferAt( index, vb, offset, _vc[index].type );
				offset += _vc[index].size;
			}

//			try {
				context.drawTriangles( _indexBuffers[i] );
//			}
//			catch ( e:Error) {
//				Log.out( "VertexIndexBuilder.BufferCopyToGPU - Error caught: " + e.message );
//				Log.out( e.getStackTrace() );
//				if ( e.errorID == 3601 ) // Error #3601: No valid index buffer set.
//					dirty = true; // Force rebuilding of index buffer. Got this error when installing MySQL Workbench while testing app
//			}
		}
		//trace ( "VertexIndexBuilder.bufferCopyToGPU - took: "  + (getTimer() - timer) + "  to process " + _buffers + " buffers" );			
	}	
	
	/*
	private function quadsCopyToVertexBuffersVector( oxelStartingIndex:int, oxelsToProcess:int, quadsToProcess:int, context3D:Context3D ):void {
		_s_totalUsed++;
		_bufferVertexMemory += quadsToProcess * Quad.VERTICES * 4; // times 4 seems true, but I dont understand why
		
		var _verticeByteArray:Vector.<Number> = new Vector.<Number>( quadsToProcess * Quad.VERTICES );

		var j:int = 0;
		var oxel:Oxel;
		var quad:Quad;
		var vertex:Number;
		for ( var index:int = oxelStartingIndex; index < oxelStartingIndex + oxelsToProcess; index++ ) {
			oxel = _oxels[index];
			if ( oxel.quads ) 
			{
				for each ( quad in oxel.quads ) 
				{
					if ( quad )
					{
						for each ( vertex in quad._verticeByteArray ) {
							_verticeByteArray[j++] =  vertex;
						}
					}
				}
			}
		}
		
		//trace("VertexIndexBuilder.quadsCopyToBuffers - startingIndex: " + oxelStartingIndex + " oxelsToProcess:" +  oxelsToProcess + " quadsToProcess: " + quadsToProcess );
		try {
			var vb:VertexBuffer3D = context3D.createVertexBuffer( quadsToProcess * Quad.VERTICES / Quad.DATA_PER_VERTEX , Quad.DATA_PER_VERTEX);
		} catch (error:ArgumentError) {
			trace('An argument error has occured');
			return;
		} catch (error:Error) {
			trace('An error has occured which is not argument related');
			return;
		}
		if ( null == vb ) {
			trace("VertexIndexBuidler.quadsCopyToBuffers - Ran out of VertexBuffers total used: " + VertexIndexBuilderPool.totalUsed() );
			return;
		}
		
		// TODO I am not testing to see the size of the _verticeByteArray or _indices.
		// what happens if they are too large? 
		// Can I ever have more then one buffer with this code? I dont see how.
		vb.uploadFromVector( _verticeByteArray, 0, quadsToProcess * 4 );
		_vertexBuffers.push(vb);
		_buffers++;
	}
*/
/*
	private function quadsCopyToIndexBuffersVector( oxelStartingIndex:int, oxelsToProcess:int, quadsToProcess:int, context3D:Context3D ):void {
		
		// NEW 3
		Log.out( "VertexIndexBuilder.quadsCopyToIndexBuffersVector - NEW 3" );
		var _offsetIndices:Vector.<uint> = new Vector.<uint>( quadsToProcess * Quad.INDICES );

		var i:int = 0;
		var oxel:Oxel;
		var quad:Quad;
		var vertex:Number;
		var indice:uint;
		for ( var index:int = oxelStartingIndex; index < oxelStartingIndex + oxelsToProcess; index++ ) {
			oxel = _oxels[index];
			if ( oxel.quads ) 
			{
				for each ( quad in oxel.quads ) 
				{
					if ( quad )
					{
						// each indice has to be offset to have a unique offset
						for each ( indice in quad._indices ) {
							_offsetIndices[i] = int(i / 6) * 4 + indice;
							i++
						}
					}
				}
			}
		}
		
		_bufferIndexMemory = quadsToProcess * Quad.INDICES;
		
		var ib:IndexBuffer3D = context3D.createIndexBuffer( quadsToProcess * Quad.INDICES );
		ib.uploadFromVector( _offsetIndices, 0, quadsToProcess * Quad.INDICES );
		_indexBuffers.push(ib);

		//Log.out( "index" );
		//for each ( var n:Number in _offsetIndices )
			//Log.out( n.toString() );
			
//		trace("VertexIndexBuilder.quadsCopyToBuffers - _offsetIndices: " + i + "(" + _offsetIndices.length +  ")  _verticeByteArray:" +  j + "(" + _verticeByteArray.length + ")  quadsToProcess: " + quadsToProcess + "  took: " + (getTimer() - timer) );
	}
*/	
	/*
	// Not using since some index is off...
	private function quadsCopyToIndexBuffersByteArray( $oxelStartingIndex:int, $oxelsToProcess:int, $quadsToProcess:int, $context3D:Context3D ):void {
		
		Log.out( "VertexIndexBuilder.quadsCopyToIndexBuffersVector - NEW 4" );
		var _offsetIndices:ByteArray = new ByteArray();
		//_offsetIndices.endian = Endian.LITTLE_ENDIAN;

		var i:int;
		var oxel:Oxel;
		var quad:Quad;
		var verticeCount:uint;
		var vertice:uint;
		var indice:uint;
		var q:int;
		for ( var index:int = $oxelStartingIndex; index < $oxelStartingIndex + $oxelsToProcess; index++ ) {
			oxel = _oxels[index];
			if ( oxel.quads ) 
			{
				for each ( quad in oxel.quads ) 
				{
					vertice = 0;
					if ( quad )
					{
						// each indice has to be offset to have a unique offset
						for each ( indice in quad._indices ) {
							//_offsetIndices[i] = int(i / 6) * 4 + indice;
							//_offsetIndices.writeUnsignedInt( int(i / 6) * 4 + indice );
							_offsetIndices.writeFloat( int(i / 6) * 4 + indice );
							i++
						}
					}
				}
			}
		}
		
		_bufferIndexMemory = $quadsToProcess * Quad.INDICES * BYTES_PER_WORD;
		
		//public function createIndexBuffer (numIndices:int) : flash.display3D.IndexBuffer3D;
		var ib:IndexBuffer3D = $context3D.createIndexBuffer( $quadsToProcess * Quad.INDICES );
		ib.uploadFromByteArray( _offsetIndices, 0, 0, $quadsToProcess * Quad.INDICES );
		_indexBuffers.push(ib);
	}
*/
/*
	private function quadsCopyToBuffersVectorGood( oxelStartingIndex:int, oxelsToProcess:int, quadsToProcess:int, context3D:Context3D ):void {
		//trace("VertexIndexBuilder.quadsCopyToBuffers - startingIndex: " + oxelStartingIndex + " oxelsToProcess:" +  oxelsToProcess + " quadsToProcess: " + quadsToProcess );
		try {
			var vb:VertexBuffer3D = context3D.createVertexBuffer( quadsToProcess * Quad.VERTICES / Quad.DATA_PER_VERTEX , Quad.DATA_PER_VERTEX);
		} catch (error:ArgumentError) {
			trace('An argument error has occured');
			return;
		} catch (error:Error) {
			trace('An error has occured which is not argument related');
			return;
		}
		if ( null == vb ) {
			trace("VertexIndexBuidler.quadsCopyToBuffers - Ran out of VertexBuffers total used: " + VertexIndexBuilderPool.totalUsed() );
			return;
		}
		
		_s_totalUsed++;
		_bufferVertexMemory += quadsToProcess * Quad.VERTICES * 4; // times 4 seems true, but I dont understand why
		
		var _verticeByteArray:Vector.<Number> = new Vector.<Number>( quadsToProcess * Quad.VERTICES );
		var _offsetIndices:Vector.<uint> = new Vector.<uint>( quadsToProcess * Quad.INDICES );

		var i:int = 0;
		var j:int = 0;
		var oxel:Oxel;
		var quad:Quad;
		var vertex:Number;
		var indice:uint;
		for ( var index:int = oxelStartingIndex; index < oxelStartingIndex + oxelsToProcess; index++ ) {
			oxel = _oxels[index];
			if ( oxel.quads ) 
			{
				for each ( quad in oxel.quads ) 
				{
					if ( quad )
					{
						for each ( vertex in quad._verticeByteArray ) {
							_verticeByteArray[j++] =  vertex;
						}
				
						// each indice has to be offset to have a unique offset
						for each ( indice in quad._indices ) {
							_offsetIndices[i] = int(i / 6) * 4 + indice;
							i++
						}
					}
				}
			}
		}
		
		// TODO I am not testing to see the size of the _verticeByteArray or _indices.
		// what happens if they are too large? 
		// Can I ever have more then one buffer with this code? I dont see how.
		vb.uploadFromVector( _verticeByteArray, 0, quadsToProcess * 4 );
		_vertexBuffers.push(vb);
		
//		for each ( var n:Number in _verticeByteArray )
//			Log.out( n.toString() );
	
		_bufferIndexMemory = quadsToProcess * Quad.INDICES;
		
		var ib:IndexBuffer3D = context3D.createIndexBuffer( quadsToProcess * Quad.INDICES );
		ib.uploadFromVector( _offsetIndices, 0, quadsToProcess * Quad.INDICES );
		_indexBuffers.push(ib);

		Log.out( "index" );
		for each ( var n:Number in _offsetIndices )
			Log.out( n.toString() );
			
		_buffers++;
		
//		trace("VertexIndexBuilder.quadsCopyToBuffers - _offsetIndices: " + i + "(" + _offsetIndices.length +  ")  _verticeByteArray:" +  j + "(" + _verticeByteArray.length + ")  quadsToProcess: " + quadsToProcess + "  took: " + (getTimer() - timer) );
	}
	*/
	
	//////////////////////////////////
	// Not currently in use - RSF 11.10.13
	//////////////////////////////////
	/*
	public function moveSkyTrianglesToGPU( context3D:Context3D ) : void {
		
		var vb:VertexBuffer3D;
		var ib:IndexBuffer3D;
		for (var i:int = 0; i < _buffers; i++) {
			//trace("VertexIndexBuilder - BufferCopyToGPU - count: " + _buffers);
			vb = _vertexBuffers[i];
			
			// Position
			context3D.setVertexBufferAt(0, vb, 0, Context3DVertexBufferFormat.FLOAT_3);
			
			ib = _indexBuffers[i];
			context3D.drawTriangles(ib);
		}
	}
	*/
	
}
}
