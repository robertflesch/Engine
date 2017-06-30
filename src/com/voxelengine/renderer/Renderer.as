/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.renderer 
{
import com.voxelengine.worldmodel.oxel.OxelBad;

import flash.display.Stage3D;
import flash.display.BitmapData;
import flash.display.Stage;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3D;
import flash.display3D.Context3DRenderMode;
import flash.events.Event;
import flash.events.ErrorEvent;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Timer;
//import flash.system.Capabilities;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.net.FileReference;

import com.adobe.images.JPGEncoder;	

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.events.ContextEvent;
import com.voxelengine.events.WindowWaterEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;

public class Renderer extends EventDispatcher 
{
	private static var _s_renderer:Renderer = new Renderer();
	public static function get renderer():Renderer 	{ return _s_renderer };

	private var timer:Timer;
	private var _width:int;
	private var _height:int;

	private var _stage3D:Stage3D;
	public function get stage3D():Stage3D { return _stage3D; }
	public function get context3D():Context3D { return _stage3D.context3D; }
	
	private var _isHW:Boolean = true;

	private var _mvp:Matrix3D = new Matrix3D();

	
	public function get width():int { return _width; }
	public function get height():int { return _height; }
	
	public function get hardwareAccelerated():Boolean { return _isHW; }
	
	private function addStageListeners():void
	{
		Globals.g_app.stage.addEventListener( Event.RESIZE, resizeEvent );
	}
	
	private function addStage3DListeners():void 
	{
		stage3D.addEventListener( Event.CONTEXT3D_CREATE, onContextCreated );
		stage3D.addEventListener( ErrorEvent.ERROR, onStage3DError );
	}

	public function init( stage:Stage ):void {
		Log.out( "Renderer.init", Log.INFO );
		setStageSize( stage.stageWidth, stage.stageHeight );
		addStageListeners();
		
		_stage3D = stage.stage3Ds[0];
		addStage3DListeners();

		stage3D.x = 0;
		stage3D.y = 0;

		const resizeInterval:Number = 1500; //amount of time you believe is enough to say that continuous resizing is ended after last discrete Event.RESIZE
		timer = new Timer(resizeInterval);
		timer.addEventListener(TimerEvent.TIMER, timerHandler);

		// This allows flash to run on older video drivers.
		//const profile:String = Context3DProfile.STANDARD_EXTENDED;
        const profile:String = Context3DProfile.BASELINE;
		// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display3D/Context3DProfile.html
        Log.out( "Renderer.init - requestContext3D Profile: " + profile, Log.INFO );
		stage3D.requestContext3D( Context3DRenderMode.AUTO, profile);
	}
	
	
	public function resizeEvent(event:Event):void {
		setStageSize( Globals.g_app.stage.stageWidth, Globals.g_app.stage.stageHeight);
		configureBackBuffer();
		//if (timer.running) {
			////Log.out("Renderer.resizeEvent - reset timer");
			//timer.reset();
		//}
		//else {
			////Log.out("Renderer.resizeEvent - timer NOT running" );
			//var t:int = getTimer()
			//ContextEvent.dispatch( new ContextEvent( ContextEvent.DISPOSED, null ) );
			//context3D.dispose();
			////Log.out("Renderer.resizeEvent - time to dispose time: " + (getTimer() - t) );
		//}
		//timer.start();			
	}		
	
	private function timerHandler(e:Event):void {
		//Log.out("Renderer.timerHandler - Timer HAS STOPPED" );
		timer.stop();
		onContext()
	}		
	
	public function setStageSize( w:int, h:int ):void {
		//Log.out( "Renderer.setStageSize w: " + w + "  h: " + h );
		_width = w;
		_height = h;
	}
	
	public function modelShot():BitmapData {
		var tmp : BitmapData = new BitmapData( _width, _height, false );
		// this draws the stage3D on the bitmap.
		render(tmp);
		return tmp;
	}
	
	public function screenShot( drawUI:Boolean ):void {
		var tmp : BitmapData = new BitmapData( _width, _height, false );
		// this draws the stage3D on the bitmap.
		render(tmp);
		
		// this adds on the gui
		if ( drawUI )
			tmp.draw( Globals.g_app.stage );
		
		var encoder:JPGEncoder = new JPGEncoder(90);
		var date:Date = new Date();
		var dateString:String = date.fullYear + "." + date.month + "." + date.day + "." + date.hours + "." + date.minutes + "." + date.seconds;
		new FileReference().save( encoder.encode(tmp), "voxelverse screenshot " + dateString + ".jpg");
		tmp.dispose();
	}

	public function setBackgroundColor( r:int=0, g:int=0, b:int=0 ):void {
		// Clears the back buffer to this color, for now it will be the "sky" color
		if ( context3D )
			context3D.clear( r/255, g/255, b/ 255, 0);
	}

	public function onContextCreated(e:Event):void {
		//Log.out( "Renderer.onContextCreated - " + e.type, Log.DEBUG );
		onContext()
	}
	
	// This handles the event created in the init function
	public function onContext():void {
		// dont initialize/reinitialize the context3D if the timer is running
		if (timer.running) {
			//Log.out("Renderer.onContext - Timer is running" );
			return
		}

		if ( context3D ) {
			context3D.enableErrorChecking = Globals.isDebug;

			configureBackBuffer();
			_isHW = context3D.driverInfo.toLowerCase().indexOf("software") == -1;
			if ( !_isHW )
				Log.out( "Renderer.onContext - SOFTWARE RENDERING - driverInfo: " + context3D.driverInfo, Log.WARN );
			else
				Log.out( "Renderer.onContext - driverInfo: " + context3D.driverInfo, Log.INFO );
				
			context3D.clear();
			ContextEvent.create( ContextEvent.ACQUIRED, context3D );
			ContextEvent.create( ContextEvent.REBUILD, context3D );
		}
	}
	
	// display message
	private function onStage3DError ( e:ErrorEvent ):void {
		//legend.text = "This content is not correctly embedded. Please change the wmode value to allow this content to run.";
		Log.out( "Renderer.onStage3DError !!!!!!!!!!!!!!!!!!!!!!!!!!!!Stage3DError occured!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", Log.ERROR );
	}		

	
	public function render( screenShot:BitmapData = null ):void 
	{
		if ( null == context3D )
		{
			//Log.out( "Renderer.render - CONTEXT NULL" );
			return;
		}
		
		if ( "Disposed" == context3D.driverInfo )
		{
			//Log.out( "Renderer.render - CONTEXT Disposed" + context3D.toString() );
			return;
		}
		

		backgroundColor();

		// New in Flash 16
		// Context3D's setFillMode()  "wireframe" or "solid".
		var controlledModel:VoxelModel = VoxelModel.controlledModel;
		var controlledModelRotation:Vector3D;

		// Very early in render cycle the controlled model may not be instantitated yet.
		var wsPositionCamera:Vector3D;
		if ( !controlledModel ) {
			wsPositionCamera = new Vector3D();
			controlledModelRotation = new Vector3D();
		}
		else {
			controlledModelRotation = controlledModel.instanceInfo.rotationGet;
			wsPositionCamera = controlledModel.instanceInfo.worldSpaceMatrix.transformVector(controlledModel.camera.current.position);
			// This does not handle the case where the player has not collided with the model yet
			// Say they are falling onto an island, and they hit the water first.
			// I should probably adjust that algorithm to account for it.
			if ( controlledModel) {
				var lcm:VoxelModel = VoxelModel.controlledModel.lastCollisionModel;
				if ( null != lcm && !lcm.dead ) {
					var camOxel:Oxel = lcm.getOxelAtWSPoint( wsPositionCamera, 4 );
					if ( camOxel && OxelBad.INVALID_OXEL != camOxel ) {
						if ( TypeInfo.WATER == camOxel.type ) {
							Globals.g_underwater = true;
							WindowWaterEvent.dispatch( new WindowWaterEvent( WindowWaterEvent.CREATE ) )
						}
						else {
							Globals.g_underwater = false;
							WindowWaterEvent.dispatch( new WindowWaterEvent( WindowWaterEvent.ANNIHILATE ) )
						}
					}
					else {
						Globals.g_underwater = false;
						WindowWaterEvent.dispatch( new WindowWaterEvent( WindowWaterEvent.ANNIHILATE ) )
					}
				}
				else {
					Globals.g_underwater = false;
					WindowWaterEvent.dispatch( new WindowWaterEvent( WindowWaterEvent.ANNIHILATE ) )
				}
			}
		}
//			trace( "Renderer.render - wsPositionCamera: " + wsPositionCamera );
		wsPositionCamera.negate();
		
		// Empty starting matrix
		_mvp.identity();
		
		_mvp.prependRotation( controlledModelRotation.x, Vector3D.X_AXIS );
		_mvp.prependRotation( controlledModelRotation.y, Vector3D.Y_AXIS );
		_mvp.prependRotation( controlledModelRotation.z, Vector3D.Z_AXIS );

		// the position of the controlled model
		_mvp.prependTranslation( wsPositionCamera.x, wsPositionCamera.y, wsPositionCamera.z ); 
		
		//var p:Vector3D = _mvp.position.clone();
		//p.negate();
		//trace( "Renderer.render - _mvp.position: " + _mvp.position + "  p: " + p );
		
		_mvp.append( perspectiveProjection(90, _width/_height, Globals.g_nearplane, Globals.g_farplane) );

		if ( Region.currentRegion )
			Region.currentRegion.modelCache.draw( _mvp, context3D );

		if ( screenShot )
			context3D.drawToBitmapData( screenShot );
		else
			context3D.present();
		
	}
	
	static private function perspectiveProjection(fov:Number = 90, aspect:Number = 1, near:Number = 1, far:Number = 2048):Matrix3D {
		var y2:Number = near * Math.tan(fov * Math.PI / 360); 
		var y1:Number = -y2;
		var x1:Number = y1 * aspect;
		var x2:Number = y2 * aspect;
		
		var a:Number = 2 * near / (x2 - x1);
		var b:Number = 2 * near / (y2 - y1);
		var c:Number = (x2 + x1) / (x2 - x1);
		var d:Number = (y2 + y1) / (y2 - y1);
		var q:Number = -(far + near) / (far - near);
		var qn:Number = -2 * (far * near) / (far - near);
		
		return new Matrix3D(Vector.<Number>([
			a, 0, 0, 0,
			0, b, 0, 0,
			c, d, q, -1,
			0, 0, qn, 0
		]));
	}
	
	private function backgroundColor():void 
	{
		if ( Region.currentRegion )
		{
			var skyColor:Vector3D = Region.currentRegion.getSkyColor();
			// Not only does this set the color, but it appears to clear the "BackBuffer"
			setBackgroundColor( skyColor.x, skyColor.y, skyColor.z );
		}
		else
			setBackgroundColor( 92, 172, 238 );
	}
	
	private function configureBackBuffer():void 
	{
			// 0	No antialiasing
			// 2	Minimal antialiasing.
			// 4	High-quality antialiasing.
			// 16	Very high-quality antialiasing.
		const antiAlias:int = 0;
		//Log.out( "Renderer.onContext - ANTI_ALIAS set to: " + antiAlias, Log.DEBUG );
		
		// false indicates no depth or stencil buffer is created, true creates a depth and a stencil buffer.
		// This HAS to be true in order for Z Depth to work
		const enableDepthAndStencil:Boolean = true;
		if ( context3D )
			context3D.configureBackBuffer( width, height, antiAlias, enableDepthAndStencil );
	}
}
}