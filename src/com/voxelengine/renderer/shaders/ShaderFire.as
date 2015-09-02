/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.shaders 
{
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix3D;

	import com.adobe.utils.v3.AGALMiniAssembler;
	
	import com.voxelengine.renderer.shaders.Shader;
	
	public class ShaderFire extends Shader {

		private	var		_textureOffsetFireU:Number = 0.0
		private	var		_textureOffsetFireV:Number = 0.0
		
		static private	var	_vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		static private	var _fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		
		public function ShaderFire( $context:Context3D ) {
			super( $context );
			createProgram( $context );
		}
		
		override public function update( mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, selected:Boolean, $isChild:Boolean = false ): Boolean {
			if ( !update_texture( $context ) )
				return false;
			
			$context.setProgram( program3D );	
			setVertexData( mvp, $vm, $context );
			setFragmentData( $isChild, $vm, $context );
			
			//$context.setCulling(Context3DTriangleFace.NONE);
			$context.setCulling(Context3DTriangleFace.BACK);
			
			var sourceFactor:String = Context3DBlendFactor.SOURCE_ALPHA;
		//	var destinationFactor:String = Context3DBlendFactor.SOURCE_COLOR;
		//  var destinationFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR
			var destinationFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
			$context.setBlendFactors( sourceFactor, destinationFactor );
			
			return true;
		}

		override protected function setVertexData( mvp:Matrix3D, $vm:VoxelModel, $context:Context3D ): void {
			// send down the view matrix
			$context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true); // aka vc0

			_textureOffsetFireV += 0.0078125;
			_textureOffsetFireU = 0;
			// ah, now I recall, I repeated the first texture at the end, so that it doesnt pop.
			if ( _textureOffsetFireV > 0.9921875 ) // this scroll DOWN a single 2048x2048 texture
				_textureOffsetFireV = 0;
				
			_offsets[0] = _textureOffsetFireU;
			_offsets[1] = _textureOffsetFireV;
			
			$context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _offsets);
		}
		
		override protected function setFragmentData( $isChild:Boolean, $vm:VoxelModel, $context:Context3D ): void { return; } // nothing needed here
		
		override public function createProgram( $context:Context3D ):void {
			// This uses 3 peices of vertex data from - setVertexData
			// va0 holds the vertex locations
			// va1 holds the UV texture offset
			// va2 holds the normal data ( in a very ineffiencent way )
			// and two constant values
			// vc0-3 hold the transform matrix for the camera
			// vc4 holds the UV offsets for the texture
			if ( null == _vertexShaderAssembler.agalcode ) {
				var vertexShader:Array =
				[
					"m44 op, va0, vc0", // transform vertex positions (va0) by the world camera data (vc0)
					"add v0, va1, vc4.xy",	// add in the UV offset (va1) and the animated offset (vc12) (may be 0 for non animated), and put in v0 which holds the UV offset
					"mov v1, va3",        	// pass texture color and brightness (va3) to the fragment shader via v1
					"mov v2, va2",        	// need to pass normals to keep shader compiler happy
					"m44 v3, va0, vc8",  	// the transformed vertices with out the camera data, works great for default AND for translated cube, rotated cube broken still
					"mov v4, va4",        	// pass light color and brightness (va4) to the fragment shader via v4
				];
				_vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, vertexShader.join("\n"));
			}
			
			// This uses 4 peices of data from vertex shader
			// v0 holds the offset UV data
			// v1 holds the texture color and brightness
			// temp registers
			// ft0 holds the texture data
			if ( null == _fragmentAssembler.agalcode ) {
				var fragmentShader:Array =
				[
					// Texture
					// texture dimension. Options: 2d, cube
					// mip mapping. Options: nomip (or mipnone , they are the same) , mipnearest, miplinear
					// texture filtering. Options: nearest, linear
					// texture repeat. Options: repeat, wrap, clamp
					"tex ft0, v0, fs0 <2d,clamp,mipnearest>", // v0 is passed in from vertex, UV coordinates
					
					/////////////////////////////////////////////////
					// TINT on base texture
					/////////////////////////////////////////////////
					"mul ft0, v1.xyz, ft0", // mutliply by texture tint - v1.xyz
					
					
					// should this or light from dynamic source take greater value?
					"mul ft0, ft0, v1.w",   // brightness - v3.w
					"mov oc ft0"
					
				];
				_fragmentAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader.join("\n"));
			}
			
			_program3D = $context.createProgram();
			_program3D.upload(_vertexShaderAssembler.agalcode, _fragmentAssembler.agalcode);
		}
		
	}
}
