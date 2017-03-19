/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.shaders 
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix3D;

	import com.voxelengine.renderer.shaders.Shader;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	public class ShaderAlpha extends Shader {

		public function ShaderAlpha( $context:Context3D ) {
			super( $context );
			createProgram( $context );
		}
		
		override public function update( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, selected:Boolean, $isChild:Boolean = false ): Boolean {
			if ( !updateTexture( $context ) )
				return false;
			
			$context.setProgram( program3D );	
			setVertexData( $mvp, $vm, $context );
			setFragmentData( $mvp, $vm, $context, $isChild );
			
			$context.setCulling(Context3DTriangleFace.NONE);
			//$context.setCulling(Context3DTriangleFace.BACK);

			var sourceFactor:String = Context3DBlendFactor.SOURCE_ALPHA;
			//var destinationFactor:String = Context3DBlendFactor.SOURCE_COLOR;
		   // var destinationFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR
			var destinationFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
			$context.setBlendFactors( sourceFactor, destinationFactor );
			
			return true;
		}
	}
}
