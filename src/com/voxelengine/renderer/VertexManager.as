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

import mx.utils.NameUtil;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.pools.VertexIndexBuilderPool;
import com.voxelengine.renderer.shaders.Shader;

public class VertexManager {
	
	private var _vertBuf:VertexIndexBuilder = null;
	private var _vertBufAlpha:VertexIndexBuilder = null;
	private var _vertBufAnimated:VertexIndexBuilder = null;
	private var _vertBufAnimatedAlpha:VertexIndexBuilder = null;
	private var _vertBufFire:VertexIndexBuilder = null;
	private var _subManagers:Vector.<VertexManager> = new Vector.<VertexManager>();
	private var _gc:GrainCursor;
	
	//private var _minGrain:uint = 9;
	private var _minGrain:uint = 10;
	
	public function set minGrain(val:uint):void {  _minGrain = val;  }
	public function get minGrain():uint { return _minGrain; }
	
	public function VertexManager( $gc:GrainCursor, $parent:VertexManager )
	{
		_gc = $gc;
		if ( null != $parent )
			$parent.childAdd( this );
		
		//var name:String = NameUtil.createUniqueName( this );
		//Log.out( "----------VertexManager.construct---------- " + name );
	}
	
	public function childAdd( $vertMan:VertexManager ):void {
		_subManagers.push( $vertMan );
		//Log.out( "VertexManager.childAdd: " + _subManagers.length );
	}
	
	public function release():void
	{
		//Log.out( "----------VertexManager.release---------- " );
		if ( _vertBuf )
		{
			VertexIndexBuilderPool.poolDispose( _vertBuf );
			_vertBuf = null;
		}
		if ( _vertBufAlpha )
		{
			VertexIndexBuilderPool.poolDispose( _vertBufAlpha );
			_vertBufAlpha = null;
		}
		
		if ( _vertBufAnimated )
		{
			VertexIndexBuilderPool.poolDispose( _vertBufAnimated );
			_vertBufAnimated = null;
		}
		
		if ( _vertBufAnimatedAlpha )
		{
			VertexIndexBuilderPool.poolDispose( _vertBufAnimatedAlpha );
			_vertBufAnimatedAlpha = null;
		}
		
		if ( _vertBufFire )
		{
			VertexIndexBuilderPool.poolDispose( _vertBufFire );
			_vertBufFire = null;
		}
	}
	
	public function dispose():void
	{
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
	
	public function drawNew( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $shaders:Vector.<Shader>, $selected:Boolean, $isChild:Boolean = false ):void {
		// need to draw ALL of the non alpha oxels first, not just the ones in THIS vertex manager.
		if ( _vertBuf && _vertBuf.length )
		{
			if ( $shaders[0].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBuf.buffersBuildFromOxels( $context );
				_vertBuf.BufferCopyToGPU( $context );
			}
		}
		
		if ( _vertBufAnimated && _vertBufAnimated.length )
		{
			if ( $shaders[1].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBufAnimated.buffersBuildFromOxels( $context );
				_vertBufAnimated.BufferCopyToGPU( $context );
			}
		}
		
		var count:int = _subManagers.length;
		for ( var i:int; i < count; i++ ) {
			_subManagers[i].drawNew( $mvp, $vm, $context, $shaders, $selected, $isChild );
		}
	}
	
	public function drawNewAlpha( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $shaders:Vector.<Shader>, $selected:Boolean, $isChild:Boolean = false ):void	{
		// Only update the shaders if they are in use, other wise 
		// we have all of the costly state changes happening for no good reason.
		// TODO - RSF - We should probably NOT upload the shaders unless they are being used.
		if ( _vertBufAnimatedAlpha && _vertBufAnimatedAlpha.length )
		{
			if ( $shaders[3].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBufAnimatedAlpha.sort();
				_vertBufAnimatedAlpha.buffersBuildFromOxels( $context );
				_vertBufAnimatedAlpha.BufferCopyToGPU( $context );
			}
		}
		
		if ( _vertBufFire && _vertBufFire.length )
		{
			if ( $shaders[4].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				_vertBufFire.sort();
				_vertBufFire.buffersBuildFromOxels( $context );
				_vertBufFire.BufferCopyToGPU( $context );
			}
		}	
		
		if ( _vertBufAlpha && _vertBufAlpha.length )
		{
			if ( $shaders[2].update( $mvp, $vm, $context, $selected, $isChild ) )
			{
				var xdist:Number = _gc.getDistance( Globals.controlledModel.modelToWorld( Globals.controlledModel.camera.center ) );
				if (  xdist < 512 ) {
					_vertBufAlpha.sorted = false;
					//Log.out( "xdist: " + xdist );
				}
				_vertBufAlpha.sort();
				_vertBufAlpha.buffersBuildFromOxels( $context );
				_vertBufAlpha.BufferCopyToGPU( $context );
			}
		}
		
		var count:int = _subManagers.length;
		for ( var i:int; i < count; i++ ) {
			_subManagers[i].drawNewAlpha( $mvp, $vm, $context, $shaders, $selected, $isChild );
		}
	}
	
	public function oxelAdd( oxel:Oxel ):void { 	
		var vib:VertexIndexBuilder = VIBGet( oxel.type, oxel.type );
		vib.dirty = true; 
		vib.oxelAdd( oxel ); 
	}
	
	public function oxelRemove( oxel:Oxel, oldType:int ):void { 
		var vib:VertexIndexBuilder = VIBGet( oxel.type, oldType );
		vib.dirty = true; 
		vib.oxelRemove( oxel ); 
	}
	
	public function VIBGet( newType:int, oldType:int ):VertexIndexBuilder
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
