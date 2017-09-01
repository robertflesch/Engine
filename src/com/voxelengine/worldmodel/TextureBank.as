/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.events.ContextEvent;
import com.voxelengine.Log;
import flash.events.Event;
import playerio.GameFS;
import playerio.PlayerIO;
import flash.display3D.Context3D;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Matrix;
import flash.utils.Dictionary;
import com.voxelengine.Globals;

public class TextureBank
{
	static private var _s_instance:TextureBank;
	static public function get instance():TextureBank {
		if ( null == _s_instance )
			_s_instance = new TextureBank();
		return _s_instance
	}

	private var _bitmapData:Dictionary = new Dictionary(true);
	private var _textures:Dictionary = new Dictionary(true);
	private var _texturesLoading:Dictionary = new Dictionary(true);

	public function TextureBank( ):void {
		ContextEvent.addListener( ContextEvent.DISPOSED, disposeContext );
		ContextEvent.addListener( ContextEvent.ACQUIRED, acquiredContext );
	}

	public function disposeContext( $ce:ContextEvent ):void {
		// TODO RSF
		// Dont I need to release texture from a when a context is lost?
		// doesnt appear so.
	}

	public function acquiredContext( $ce:ContextEvent ):void {
		//Log.out("TextureBank.reinitialize" );
		for ( var key:String in _bitmapData )
		{
			_textures[key] = null;
			var bmp:Bitmap = _bitmapData[key];
			var tex:Texture = uploadTexture( $ce.context3D, bmp, true );
			_textures[key] = tex;
		}
	}

	public function getTexture( $context:Context3D, textureNameAndPath:String ):Texture {
		// is this texture loaded already?
		var tex:Texture = _textures[textureNameAndPath];
		if ( tex )
			return tex;

		var result:Boolean = _texturesLoading[ textureNameAndPath ];
		if ( false == result )
			loadTexture( $context, textureNameAndPath );

		//Log.out("TextureBank.getTexture - texture not found: " + textureNameAndPath, Log.ERROR );

		return null;
	}

	static private function onFileLoadError(event:IOErrorEvent):void {
		Log.out("TextureBank.onFileLoadError - FILE LOAD ERROR, DIDN'T FIND: Insufficient Info returned by event look at previous loads " + event.target.url, Log.ERROR );
	}

	private function loadTexture( $context:Context3D, textureNameAndPath:String ):void {
		_tempContext = $context;
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onTextureLoadComplete);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
		//Log.out( "TextureBank.loadTexture - loading: " + Globals.appPath + textureNameAndPath );

		if ( "/" == Globals.appPath ) {
			var fs:GameFS = PlayerIO.gameFS(Globals.GAME_ID);
			var resolvedFilePath:String = fs.getUrl(Globals.appPath + textureNameAndPath);
			loader.load(new URLRequest(resolvedFilePath));
		} else {
			loader.load(new URLRequest( Globals.appPath + textureNameAndPath ));

		}


		_texturesLoading[textureNameAndPath] = true;
	}

	static public function removeGlobalAppPath( completePath:String ):String {
		var lastIndex:int = completePath.lastIndexOf( "assets/textures/" );
		var fileName:String = completePath;
		if ( -1 != lastIndex )
			fileName = completePath.substr( lastIndex );

		return fileName;
	}

	private var _tempContext:Context3D;
	public function onTextureLoadComplete (event:Event):void {
		var textureBitmap:Bitmap = Bitmap(LoaderInfo(event.target).content);// .bitmapData;
		var fileNameAndPath:String = event.target.url;
		Log.out( "TextureBank.onTextureLoadComplete: " + fileNameAndPath );

		var tex:Texture = uploadTexture( _tempContext, textureBitmap );
		var textureNameAndPath:String = removeGlobalAppPath(fileNameAndPath);
		Log.out( "TextureBank.onTextureLoadComplete: " + textureNameAndPath );

		_bitmapData[textureNameAndPath] = textureBitmap;
		_textures[textureNameAndPath] = tex;
		_texturesLoading[textureNameAndPath] = false;
		_tempContext = null;
	}

	static public function uploadTexture( $context:Context3D, bmp:Bitmap, useMips:Boolean = true ):Texture {
		var tex:Texture = $context.createTexture(bmp.width, bmp.height, Context3DTextureFormat.BGRA, false);
		if ( useMips )
			uploadTextureWithMipmaps( tex, bmp.bitmapData );
		else
			tex.uploadFromBitmapData( bmp.bitmapData, 0);

		return tex;
	}

	static private function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):void {
		var ws:int = src.width;
		var hs:int = src.height;
		var level:int = 0;
		var tmp:BitmapData;
		var transform:Matrix = new Matrix();

		tmp = new BitmapData(src.width, src.height, true, 0x00000000);

		while ( ws >= 1 && hs >= 1 ) {
			tmp.draw(src, transform, null, null, null, true);
			dest.uploadFromBitmapData(tmp, level);
			transform.scale(0.5, 0.5);
			level++;
			ws >>= 1;
			hs >>= 1;
			if (hs && ws)
			{
				tmp.dispose();
				tmp = new BitmapData(ws, hs, true, 0x00000000);
			}
		}
		tmp.dispose();
	}

//	private function uploadTextureNoMip(dest:Texture, src:BitmapData):void {
//		//var texture:Texture = _context.createTexture(image.width, image.height, Context3DTextureFormat.BGRA, false);
//		//texture.uploadFromBitmapData(image);
//		//_context.setTextureAt(sampler, texture);
//
//		dest.uploadFromBitmapData(src, 0);
//	}
}
}
