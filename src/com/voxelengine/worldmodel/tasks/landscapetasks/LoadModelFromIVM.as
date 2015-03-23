/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import com.developmentarc.core.tasks.tasks.ITask;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LandscapeTask;
	import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class LoadModelFromIVM extends LandscapeTask 
	{		
		public function LoadModelFromIVM( $guid:String, $layer:LayerInfo, $taskType:String = "LoadModelFromIVM", $taskPriority:int = TASK_PRIORITY ):void {
			//Log.out( "LoadModelFromIVM.construct " );
			_layer = $layer;
			_startTime = getTimer();
			super( $guid, $layer, $taskType, $taskPriority );
			throw new Error( "LoadModelFromIVM - not implemented" );

		}
		
		// use data = for model guid
		override public function start():void {
			var timer:int = getTimer();
			super.start() // AbstractTask will send event

			//var fileName:String = _layer.data;
			//var index:int = fileName.indexOf( '*' );
			//if ( -1 != index )
			//{
				//var rand:int = Math.random() * 4 + 1;
				//fileName = fileName.replace( "*", String( rand ) );
				//_layer.replaceData( fileName );
			//}
				//
			//var ba:ByteArray = Globals.findIVM( fileName );
			//if ( ba )
			//{
				//loadByteArray( ba );
				//return;
			//}
			//
			//if ( !Globals.isGuid( fileName ) )
			//{
				//loadFromFile( fileName )
			//}
			//else
			//{
				//// ModelManager is already loading this
				//Log.out( "LoadModelFromIVM.start - How do I end up here?", Log.ERROR );
				//super.complete() // AbstractTask will send event
			//}
		}
		
		private	function loadFromFile( fileName:String ):void { 	
			var path:String = Globals.modelPath + fileName + ".ivm";
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.load(new URLRequest( path ));
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onIVMLoad);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorAction);			
			
			// byte array data has been successfully loaded from the local IVM file
			function onIVMLoad(event:Event):void	{
				//var ba:ByteArray = event.target.data;
				//Globals.addIVM( _layer.data, ba );
				//loadByteArray( ba );
			}

		}
		
		private	function errorAction(e:IOErrorEvent):void {
			Log.out( "LoadModelFromIVM.errorAction: " + e.toString(), Log.ERROR );
			super.complete() // AbstractTask will send event
		}	

		private function loadByteArray( $ba:ByteArray ):void {
			
			var task:ITask = new LoadFromByteArray( _instanceGuid, _layer );
			Globals.g_landscapeTaskController.addTask( task );

			super.complete() // AbstractTask will send event
		}

		
		override public function cancel():void {
			// TODO stop this somehow?
			super.cancel();
		}
	}
}
