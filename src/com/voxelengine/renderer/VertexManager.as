/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.renderer {

import com.voxelengine.events.ContextEvent;
import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.utils.getTimer;
import flash.utils.Timer;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.pools.VertexIndexBuilderPool;
import com.voxelengine.renderer.shaders.*;

public class VertexManager {
	
	private var _vertBuf:VertexIndexBuilder = null;
	private var _vertBufAlpha:VertexIndexBuilder = null;
	private var _vertBufAnimated:VertexIndexBuilder = null;
	private var _vertBufAnimatedAlpha:VertexIndexBuilder = null;
	private var _vertBufFire:VertexIndexBuilder = null;
	
	private var _gc:GrainCursor;
	private var _shaders:Vector.<Shader>;

//	private var _subManagers:Vector.<VertexManager> = new Vector.<VertexManager>();
	
	public function VertexManager( $gc:GrainCursor, $parent:VertexManager )
	{
		_gc = $gc;
		//if ( null != $parent )
			//$parent.childAdd( this );
		
		//var name:String = NameUtil.createUniqueName( this );
		//Log.out( "----------VertexManager.construct---------- " + name );
		ContextEvent.addListener( ContextEvent.DISPOSED, disposeContext );
		ContextEvent.addListener( ContextEvent.ACQUIRED, acquiredContext );
		ContextEvent.addListener( ContextEvent.REBUILD, rebuildContext );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start context operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function createShaders($context:Context3D):void	{
		_shaders = new Vector.<Shader>;
		var shader:Shader = null;
		_shaders.push( new ShaderOxel($context) ); // oxel
		
		shader = new ShaderOxel($context); // animated oxel
		shader.isAnimated = true;
		_shaders.push( shader );
		
		_shaders.push( new ShaderAlpha($context) ); // alpha oxel
		
		shader = new ShaderAlphaAnimated($context); // animated alpha oxel
		shader.isAnimated = true;
		_shaders.push( shader );
		
		shader = new ShaderFire($context); // fire
		shader.isAnimated = true;
		_shaders.push( shader );
	}
	
	public function acquiredContext( $ce:ContextEvent ):void {
		setAllTypesDirty();
		for each ( var shader:Shader in _shaders )
			shader.createProgram( $ce.context3D );
	}

	public function rebuildContext( $ce:ContextEvent ):void {
		for each ( var shader:Shader in _shaders )
			shader.updateTexture( $ce.context3D, true );
	}

	public function disposeContext( $ce:ContextEvent ):void {
		for each ( var shader:Shader in _shaders )
			shader.dispose();
			
//		if (oxel)
//			oxel.dispose();
		//trace("VertexManager.dispose: " + _name );
		if ( _vertBuf )
			_vertBuf.dispose();

		if ( _vertBufAlpha )
			_vertBufAlpha.dispose();
		
		if ( _vertBufAnimated )
			_vertBufAnimated.dispose();
		
		if ( _vertBufAnimatedAlpha )
			_vertBufAnimatedAlpha.dispose();
		
		if ( _vertBufFire )
			_vertBufFire.dispose();
	}
	
	
	
	//public function childAdd( $vertMan:VertexManager ):void {
		//_subManagers.push( $vertMan );
		////Log.out( "VertexManager.childAdd: " + _subManagers.length );
	//}
	
	public function release():void
	{
		//Log.out( "----------VertexManager.release---------- " );
		if ( _vertBuf ) {
			VertexIndexBuilderPool.poolDispose( _vertBuf );
			_vertBuf = null;
		}
		if ( _vertBufAlpha ) {
			VertexIndexBuilderPool.poolDispose( _vertBufAlpha );
			_vertBufAlpha = null; 
		}
		if ( _vertBufAnimated ) {
			VertexIndexBuilderPool.poolDispose( _vertBufAnimated );
			_vertBufAnimated = null;
		}
		if ( _vertBufAnimatedAlpha ) {
			VertexIndexBuilderPool.poolDispose( _vertBufAnimatedAlpha );
			_vertBufAnimatedAlpha = null;
		}
		if ( _vertBufFire ) {
			VertexIndexBuilderPool.poolDispose( _vertBufFire );
			_vertBufFire = null;
		}

		ContextEvent.removeListener( ContextEvent.DISPOSED, disposeContext );
		ContextEvent.removeListener( ContextEvent.ACQUIRED, acquiredContext );
		ContextEvent.removeListener( ContextEvent.REBUILD, rebuildContext );

	}
	
	public function drawNew( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void {
		// need to draw ALL of the non alpha oxels first, not just the ones in THIS vertex manager.
		if ( null == _shaders )
			createShaders( $context );
			
		if ( _vertBuf && _vertBuf.length && ( _vertBuf.hasFaces || _vertBuf.dirty ) )
		{
			if ( _shaders[0].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBuf.buffersBuildFromOxels( $context );
				_vertBuf.bufferCopyToGPU( $context );
			}
		}
		
		if ( _vertBufAnimated && _vertBufAnimated.length && ( _vertBufAnimated.hasFaces || _vertBufAnimated.dirty ) )
		{
			if ( _shaders[1].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBufAnimated.buffersBuildFromOxels( $context );
				_vertBufAnimated.bufferCopyToGPU( $context );
			}
		}
		
		//var count:int = _subManagers.length;
		//for ( var i:int; i < count; i++ ) {
			//_subManagers[i].drawNew( $mvp, $vm, $context, $selected, $isChild );
		//}
	}
	
	public function drawNewAlpha( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean = false ):void	{
		// Only update the shaders if they are in use, other wise 
		// we have all of the costly state changes happening for no good reason.
		// TODO - RSF - We should probably NOT upload the shaders unless they are being used.
		if ( _vertBufAnimatedAlpha && _vertBufAnimatedAlpha.length && ( _vertBufAnimatedAlpha.hasFaces || _vertBufAnimatedAlpha.dirty ) ) {
			if ( _shaders[3].update( $mvp, $vm, $context, $selected, $isChild ) ) {
				_vertBufAnimatedAlpha.sort();
				_vertBufAnimatedAlpha.buffersBuildFromOxels( $context );
				_vertBufAnimatedAlpha.bufferCopyToGPU( $context );
			}
		}
		
		if ( _vertBufFire && _vertBufFire.length && ( _vertBufFire.hasFaces || _vertBufFire.dirty ) ) {
			if ( _shaders[4].update( $mvp, $vm, $context, $selected, $isChild ) ) {
				_vertBufFire.sort();
				_vertBufFire.buffersBuildFromOxels( $context );
				_vertBufFire.bufferCopyToGPU( $context );
			}
		}	
		
		if ( _vertBufAlpha && _vertBufAlpha.length && ( _vertBufAlpha.hasFaces || _vertBufAlpha.dirty ) ) {
			if ( _shaders[2].update( $mvp, $vm, $context, $selected, $isChild ) ) {
				// TODO anyway to optimise this? its causing a huge amount of vector allocations
				//var xdist:Number = _gc.getDistance( VoxelModel.controlledModel.modelToWorld( VoxelModel.controlledModel.camera.center ) );
				//if (  xdist < 512 ) {
					//_vertBufAlpha.sorted = false;
					////Log.out( "xdist: " + xdist );
				//}
				_vertBufAlpha.sort();
				_vertBufAlpha.buffersBuildFromOxels( $context );
				_vertBufAlpha.bufferCopyToGPU( $context );
			}
		}
		
		//var count:int = _subManagers.length;
		//for ( var i:int; i < count; i++ ) {
			//_subManagers[i].drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		//}
	}
	
	public function oxelAdd( $oxel:Oxel ):void { 	
		var vib:VertexIndexBuilder = VIBGet( $oxel.type );
		vib.oxelAdd( $oxel ); 
	}
	
	public function oxelRemove( $oxel:Oxel ):void { 
		var vib:VertexIndexBuilder = VIBGet( $oxel.type );
		vib.oxelRemove( $oxel ); 
		// I think answer to this is to not worry about it.
		// If everything is gone, then next time it is built, it will be empty.
//		if ( 0 == vib.length )
//			Log.out( "VertexManger.oxelRemove - TODO how do I release every when last oxel is removed?", Log.WARN );
	}

	public function setAllTypesDirty():void {
		if ( _vertBuf )
			_vertBuf.dirty = true;
		if ( _vertBufAlpha )
			_vertBufAlpha.dirty = true;
		if ( _vertBufAnimated )
			_vertBufAnimated.dirty = true;
		if ( _vertBufAnimatedAlpha )
			_vertBufAnimatedAlpha.dirty = true;
		if ( _vertBufFire )
			_vertBufFire.dirty = true;
	}

	public function VIBGet( $type:uint ):VertexIndexBuilder
	{
		var ti:TypeInfo = TypeInfo.typeInfo[$type];
		if ( ti.animated  ) 
		{
    		if ( ti.alpha )
			{
				if ( ti.flame )
				{
					if ( !_vertBufFire )
						_vertBufFire = VertexIndexBuilderPool.poolGet();
					return _vertBufFire;
				}
				else
				{
					if ( !_vertBufAnimatedAlpha )
						_vertBufAnimatedAlpha = VertexIndexBuilderPool.poolGet();
					return _vertBufAnimatedAlpha;
				}
			}	
			else	
			{
				if ( !_vertBufAnimated )
					_vertBufAnimated = VertexIndexBuilderPool.poolGet();
				return _vertBufAnimated;
			}	
		} 
		else 
		{
    		if ( ti.alpha ) 
			{
				if ( !_vertBufAlpha )
					_vertBufAlpha = VertexIndexBuilderPool.poolGet();
				return _vertBufAlpha;
			}	
			else 
			{
				if ( !_vertBuf )
					_vertBuf = VertexIndexBuilderPool.poolGet();
				return _vertBuf;
			}
		}
		return null;
	}
	
	public function VIBGetOld( newType:int, oldType:int ):VertexIndexBuilder
	{
		var VIBType:int = 0;
		// We have to remeber what is WAS, so we can remove it form correct buffer
		if ( TypeInfo.INVALID == oldType )
			VIBType = newType;
		else
			VIBType = oldType;
			
		if ( TypeInfo.typeInfo[VIBType].animated  ) 
		{
    		if ( TypeInfo.typeInfo[VIBType].alpha )
			{
				if ( TypeInfo.typeInfo[VIBType].flame )
				{
					if ( !_vertBufFire )
						_vertBufFire = VertexIndexBuilderPool.poolGet();
					return _vertBufFire;
				}
				else
				{
					if ( !_vertBufAnimatedAlpha )
						_vertBufAnimatedAlpha = VertexIndexBuilderPool.poolGet();
					return _vertBufAnimatedAlpha;
				}
			}	
			else	
			{
				if ( !_vertBufAnimated )
					_vertBufAnimated = VertexIndexBuilderPool.poolGet();
				return _vertBufAnimated;
			}	
		} 
		else 
		{
    		if ( TypeInfo.typeInfo[VIBType].alpha ) 
			{
				if ( !_vertBufAlpha )
					_vertBufAlpha = VertexIndexBuilderPool.poolGet();
				return _vertBufAlpha;
			}	
			else 
			{
				if ( !_vertBuf )
					_vertBuf = VertexIndexBuilderPool.poolGet();
				return _vertBuf;
			}
		}
		return null;
	}
}
}
