/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer.shaders 
{
	import com.voxelengine.renderer.lamps.ShaderLight;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.TextureBank;
	import flash.display3D.textures.Texture;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.renderer.Quad;
	
	import com.adobe.utils.v3.AGALMiniAssembler;
	
	
	public class Shader {

		static private      var     _lastTextureName:String;
		static private      var     _s_lights:Vector.<ShaderLight> = new Vector.<ShaderLight>();
		static protected	var		_textureOffsetU:Number = 0.0;
		static protected	var		_textureOffsetV:Number = 0.0;
		
		protected			var		_program3D:Program3D = null;	
		protected			var		_textureName:String = "assets/textures/oxel.png";
		protected			var		_textureScale:Number = 2048; 
		protected			var		_isAnimated:Boolean = false;
		static private		var 	_vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		static private		var 	_fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();

						
		protected 			var 	_offsets:Vector.<Number> = Vector.<Number>([0,0,0,0]);
		protected 			var 	_constants:Vector.<Number> = Vector.<Number>([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
		
		static public  function     lights( index:int ):ShaderLight			{ return _s_lights[ index ]; }
		static public  function     lightCount():int 						{ return _s_lights.length; }
		static public  function     lightAdd( light:ShaderLight ):void 		{ _s_lights.push( light ); }
		static public  function     lightsClear():void 						{ 
			_s_lights = new Vector.<ShaderLight>(); 
		}
		
		static public  function     animationOffsetsUpdate( $elapsed:int ):void 						{ 
			//_textureOffsetV -= 0.000006 * $elapsed;
			// after removing the division by grain size in shader, I needed to slow it down a bit.
			_textureOffsetV -= 0.000001 * $elapsed;
			                   
			//if ( _textureOffsetV < -0.888671875 )
			if ( _textureOffsetV < -0.9296875 )  //Texture length - 64, so we dont run past end.
				_textureOffsetV = 0;
			//trace( 	_textureOffsetV )
		}
		
		public function		get		textureName():String  					{ return _textureName; }
		public function		set		textureName(val:String):void 			{ _textureName = val; }
		public function		get		textureScale():Number  					{ return _textureScale; }
		public function		set		textureScale(val:Number):void 			{ _textureScale = val; }
		public function		get		program3D():Program3D 					{ return _program3D; }
		public function		get		isAnimated():Boolean  					{ return _isAnimated; }
		public function		set		isAnimated(value:Boolean):void  		{ _isAnimated = value; }
		

		
		public function Shader( $context:Context3D ) {
			Quad.textureScaleSet(textureScale);
		}
		
		public function release():void { dispose(); }
		//public function reinitialize( $context:Context3D ):void  { _context = $context; }
		public function update( mvp:Matrix3D, vm:VoxelModel, $context:Context3D, selected:Boolean, $isChild:Boolean = false ): Boolean { throw new Error( "Shader.update - NEEDS TO BE OVERRIDED" ); return true; }
		
		public function createProgram( $context:Context3D ):void {
			//Log.out( "Shader.createProgram" );
//			_context = $context;
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
					"m44 vt0, va0, vc0", // transform vertex positions (va0) by the world camera data (vc0)
					// this result has the camera angle as part of the matrix, which is not good when calculating light
					"mov op, vt0",       // move the transformed vertex data (vt0) in output position (op)

//					"div vt1, vc12.xy, va1.z",        // grain, this did NOT work.
					"mov vt1, vc12.xy",       // move the transformed UV offset

					"add v0, va1.xy, vt1.xy", // add in the UV offset (va1) and the animated offset (vc12/vt1) (may be 0 for non animated), and put in v0 which holds the UV offset
					"mov v1, va2",        	// pass texture color and brightness (va3) to the fragment shader via v1

					// the transformed vertices without the camera data
	//				"mov v3, vt0",       	// no no no
	//				"mov v3, va0",       	// works great for default. Not for translated cube
	//				"m44 v3, va0, vc0",  	// works great for default. Not for translated cube
	//				"m44 v3, va0, vc4",  	// works great for default. Not for translated cube
					"m44 v3, va0, vc8",  	// the transformed vertices with out the camera data, works great for default AND for translated cube, rotated cube broken still
					"mov v4, va3",        	// pass light color and brightness (va3) to the fragment shader via v4

					//"m44 v5, va2, vc4",  	// transform vertex normal, send to fragment shader
					// A non working method for a generated normal
					"nrm vt1.xyz, va0.xyz",	// normalize the vertex (va0) into vt1. we need to mask the W component as the normalize operation only work for Vector3D
					"mov vt1.w, va0.w",		// Set the w component back to its original value from va0 into vt1
					"mov v2, vt1"			// Interpolate the normal (vt1) into variable register v2
				];
				_vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, vertexShader.join("\n"));
			}
			
			// This uses 4 peices of data from vertex shader
			// v0 holds the offset UV data
			// v1 holds the texture color and brightness
			// v2 holds the rotated normal data for the triangle
			// v3 holds the transformed vertex data
			// this shader also uses 2 values pass in thru the  -setFragmentData
			// fc0 - light pos
			// fc1 - dynamic lighting values
			// fc2 - dynamic light colors
			// temp registers
			// ft0 base texture data
			// ft1 transformed vertex data minus the light position
			// ft2 lambert lighting data
			// ft3 distance calculations
			// ft4 base texture time brightness
			if ( null == _fragmentAssembler.agalcode ) {
				var fragmentShader:Array =
				[
					// Texture
					// texture dimension. Options: 2d, cube
					// mip mapping. Options: nomip (or mipnone , they are the same) , mipnearest, miplinear
					// texture filtering. Options: nearest, linear
					// texture repeat. Options: repeat, wrap, clamp
					// 0.0625 is texture bias for adjusting the mipmap distance
					"tex ft0, v0, fs0 <2d,clamp,mipnearest,0.0625>",
					
					// http://pgstudios.org/old_tut_archive.html
					// Fix for Pre-Multiplied Alpha in PNGs
					// Wow, gives really strange effect
					//"div ft0.rgb, ft0.rgb, ft0.a",  // un-premultiply png
					
					/////////////////////////////////////////////////
					// TINT on base texture
					"mul ft0.xyz, v1.xyz, ft0.xyz", // mutliply by texture tint - v1.xyz
					/////////////////////////////////////////////////
					
					/////////////////////////////////////////////////
					// light from brightness
					"mul ft4.xyz, v4.xyz, ft0.xyz", // modify the texture by multiplying by the light color
					/////////////////////////////////////////////////
					
					/////////////////////////////////////////////////
					// ALPHA VALUES --------------------------------
					// take the smallest value from the tint and the source texture
					"min ft4.w, v1.w, ft0.w",
					// END ALPHA VALUES --------------------------------
					/////////////////////////////////////////////////
					
	"mul ft4, v4.w, ft4", 	// Ambient Occlusion - multiply by texture brightness ColorUINT.w
					
					/////////////////////////////////////////////////
					// light from dynamic lights
					/////////////////////////////////////////////////
					// normalize the light position
					"sub ft1, v3, fc0",		// subtract the light position from the transformed vertex postion
					
					"nrm ft1.xyz, ft1",     // normalize the light position (ft1)
															 
					// non flat shading
					"dp3 ft2, ft1, v2",     // dot the transformed normal with light direction
					"sat ft2, ft2",     	// Clamp ft2 between 1 and 0, put result in ft2.
					"mul ft2, ft2, ft0",    // multiply colorized texture by light amount
					
					// calculate the distance from the vertex
					// ft3.w holds the total distance
					"sub ft3, v3, fc0",		// subtract the light position from the transformed vertex postion
					"mul ft3, ft3, ft3", 	// square it
					"add ft3.w, ft3.x, ft3.y", // add w = x^2 + y ^2
					"add ft3.w, ft3.w, ft3.z", // add w + z^2
					"mov ft3.xyz, fc2.w", // set other components to 0 (fc2.w)
					"sqt ft3.w, ft3.w", // take sqr root - gives us distance to this vertex
					
					// now that we have the distance to the vertex
					// we use the rEnd - distance / rEnd - rStart formula to calcuate light influence
					// ft5 holds the light value for personal light
					"sub ft5.x, fc1.z, ft3.w", // rend - distance
					"mov ft3.z, fc1.z", // have to move rend to a non constant register (ft3.z) before I can operate on it
					"sub ft5.y, ft3.z, fc1.y", // rend - rstart
					"div ft5.z, ft5.x, ft5.y",  // rend - r / rend - rstart
					"mov ft5.xyw, fc2.w", // clear out other components to 0
					"mul ft2, ft0, ft5.z",  // multiple the UNlit texture, with the attenuated light effect !Critical Change, otherwise the torch is dependant on the static texture color.
					"mul ft2.xyz, ft2.xyz, fc2.xyz",  // take result and multiple by light color
					
	"mul ft2, v4.w, ft2", 	// Ambient Occlusion - take result and multiple vertex brightness
					// END light from dynamic lights
					/////////////////////////////////////////////////
					
					////////////////////////////////////////////////////////////////////////////
					// FOG
					//"mul ft6",
					// END FOG
					////////////////////////////////////////////////////////////////////////////
					"max ft3, ft2.xyz, ft4.xyz",    // take the larger value between the dynamic light and static light, for the RGB values
					// grab the alpha value from the min of original texture and tint value.
					"max ft3.w, ft4.w, ft4.w",
					"sat ft2, ft3",     	// Clamp ft2 between 1 and 0, put result in ft2.

					////////////////////////////////////////////////////////////////////////////
					// OUTPUT
					// mixed static and dynamic values
					"mov oc ft2"
					// static only values
					// "mov oc ft4"
					////////////////////////////////////////////////////////////////////////////
				];
				
				_fragmentAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader.join("\n"));
			}
			
			_program3D = $context.createProgram();
			_program3D.upload( _vertexShaderAssembler.agalcode, _fragmentAssembler.agalcode);
		}
		
		protected function constantsReset():void {
			
				var i:int = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
				_constants[i++] = 0;
		}

		protected function setFragmentData( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $isChild:Boolean  ): void {
			// TODO - pass in multiple lights
			var lp:Vector3D;
			var light:ShaderLight;
			if ( 0 < Shader.lightCount() ) { // This is currently ALWAYS true, no light is just a black light
				light = lights(0);

				// this seems to be useless, but I might need to to light children models correctly.
				if ( $isChild ) {
					lp = $mvp.position;
				} else {
					lp = light.position;
				}

				var i:int = 0;
				_constants[i++] = lp.x; // light position    |
				_constants[i++] = lp.y; //                   |
				_constants[i++] = lp.z; //                   | FC0
				_constants[i++] = lp.w; //                   |_
				_constants[i++] = 0.5; // fc1.x -not used    |
				_constants[i++] = light.nearDistance; //     |
				_constants[i++] = light.endDistance; // 	 | FC1
				_constants[i++] = 1;//                       |_
				_constants[i++] = light.color.x; //          |
				_constants[i++] = light.color.y; //          |
				_constants[i++] = light.color.z; //          | FC2
				_constants[i++] = 0;       //                |_
			}
			else
				constantsReset();
			
			// This allows for moving light posision, light color
			$context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT , 0 , _constants );
		}

		protected function setVertexData( mvp:Matrix3D, $vm:VoxelModel, $context:Context3D ): void {
			// send down the view matrix
			$context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true); // aka vc0
			
			// and the inverted model matrix, which is world position ( free from camera data )
			$context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, $vm.instanceInfo.invModelMatrix, true); // aka vc4
			
			$context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, $vm.instanceInfo.worldSpaceMatrix, true); // aka vc8
			
			if ( _isAnimated ) 
				animationOffsets();
			
			$context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 12, _offsets);
		}
		
		public function animationOffsets():void { 
			_offsets[0] = _textureOffsetU;
			_offsets[1] = _textureOffsetV;
		}
		
		public function setTextureInfo( json:Object ):void {
			if ( json.textureName )
				_textureName = json.textureName;
			if ( json.textureScale )
				_textureScale = Number(json.textureScale);
		}
		
		public function updateTexture($context:Context3D, $forceUpdate:Boolean = false ): Boolean {

			if ( _lastTextureName == textureName && !$forceUpdate )
				return true;

			var tex0:Texture = TextureBank.instance.getTexture( $context, textureName );
			//var tex1:Texture = TextureBank.instance.getTexture( "assets/textures/x.png" );
			if ( !tex0 )
			{
				//Log.out( "Shader.update_texture - not ready textureName: " + textureName );
				return false;
			}
			if ( $context )
			{
				//Log.out( "Shader.update_texture - textureName: " + textureName );
				//$context.setTextureAt( 0, null );
				//$context.setTextureAt( 1, null );
				$context.setTextureAt( 0, tex0 );
				_lastTextureName = textureName;
				//$context.setTextureAt( 1, tex1 );
			}
			Quad.textureScaleSet(textureScale);
			
			return true;
		}
	
		public function dispose():void {
			_textureOffsetU = 0.0;
			_textureOffsetV = 0.0;
//			_context = null;
			if ( null != _program3D ) {
				_program3D.dispose();
				_program3D = null;
			}
			//Log.out( "Shader.dispose" );
		}
	}
}
