/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI {

import flash.display.Bitmap;
import flash.events.Event;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.renderer.Renderer;

public class LoadingImage extends VVCanvas
{
    static private var _count:int;
    static public function init():void {
        LoadingImageEvent.addListener( LoadingImageEvent.CREATE, create );
        LoadingImageEvent.addListener( LoadingImageEvent.DESTROY, destroy );
        LoadingImageEvent.addListener( LoadingImageEvent.ANNIHILATE, annihilate );
    }

    static private function annihilate(e:LoadingImageEvent):void {
        Log.out( "LoadingImage.annihilate called count: " + _count, Log.WARN );
        _count = 0;
        if ( LoadingImage.isActive ) {
            LoadingImage._s_currentInstance.remove();
        }
    }

    static private function create(e:LoadingImageEvent):void {
        _count++;
        //Log.out( "LoadingImage.create called count: " + _count, Log.WARN );
        if ( !LoadingImage.isActive )
            new LoadingImage();
    }

    static private function destroy(e:LoadingImageEvent):void {
        if ( 0 < _count )
            _count--;
        //Log.out( "LoadingImage.destroy called count: " + _count, Log.WARN );
        if ( LoadingImage.isActive && _count == 0 ) {
            //Log.out( "LoadingImage.DESTROYED", Log.WARN );
            LoadingImage._s_currentInstance.remove();
        }
    }

    static private var _s_currentInstance:LoadingImage = null;
    static private function get isActive():Boolean { return _s_currentInstance ? true: false; }

    private const _angle:Number = 0.5236;
    private var _count:int = 0;
    private var _outline:Image;
    [Embed(source='../../../../embed/textures/loadingCursor.png')]
    private var _splashImageClass:Class;


    public function LoadingImage():void {
        //Log.out( "LoadingImage.constructor", Log.WARN );
        super( Renderer.renderer.width, Renderer.renderer.height );
        _s_currentInstance = this;

        var _splashImage:Bitmap = (new _splashImageClass() as Bitmap);
        _outline = new Image( _splashImage );
        addElement( _outline );

        display( _outline.x, _outline.x );
        onResize( null );

        addEventListener(UIOEvent.REMOVED, onRemoved );
        Globals.g_app.stage.addEventListener( Event.RESIZE, onResize );
        AppEvent.addListener( Event.ENTER_FRAME, onEnterFrame )
    }

    private function onResize(event:Event):void {
        // still kinda funky in placement.... but works.
        _outline.x = Renderer.renderer.width / 2 - _outline.x / 2;
        _outline.y = Renderer.renderer.height / 2 - _outline.y / 2
    }

    // Window events
    private function onRemoved( event:Event ):void {
        removeEventListener(UIOEvent.REMOVED, onRemoved );
        Globals.g_app.stage.removeEventListener( Event.RESIZE, onResize );
        AppEvent.removeListener( Event.ENTER_FRAME, onEnterFrame );

        _s_currentInstance = null;
    }

    private function onEnterFrame( e:Event ):void {
        rotateImage( _angle );
    }

    private function rotateImage(degrees:Number):void {
        _count++;

        if ( 0 == _count % 5 ) {
            // Calculate rotation and offsets
            var offsetWidth:Number = _outline.width/2.0;
            var offsetHeight:Number =  _outline.height/2.0;

            // Perform rotation
            var matrix:Matrix = new Matrix();
            matrix.translate(-offsetWidth, -offsetHeight);
            matrix.rotate(degrees); // radians);
            matrix.translate(+offsetWidth, +offsetHeight);
            matrix.concat(_outline.transform.matrix);
            _outline.transform.matrix = matrix;
        }
    }
}
}