/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	import playerio.DatabaseObject;
	import playerio.PlayerIOError;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import com.developmentarc.core.tasks.tasks.AbstractTask;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.server.Persistance;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;

	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class LoadModelFromBigDB extends AbstractTask 
	{		
		static private var _count:int = 0;
		private var _guid:String;
		protected var _startTime:int;
		
		public function LoadModelFromBigDB( $guid:String, $layer:LayerInfo = null ):void {
			//Log.out( "LoadModelFromBigDB.construct " );
			_guid = $guid
			_startTime = getTimer();
			//public function AbstractTask(type:String, priority:int = 5, uid:Object = null, selfOverride:Boolean = false, blocking:Boolean = false)
			super( _guid );
			_count++;
		}
		
		override public function start():void
		{
			Log.out( "LoadModelFromBigDB.start for guid:" + _guid );
			var timer:int = getTimer();
			super.start() // AbstractTask will send event
			
			Persistance.loadObject( "voxelModels", _guid, successHandler, errorHandler );
		}
		
		private function successHandler($dbo:DatabaseObject):void 
		{ 
			Log.out( "LoadModelFromBigDB.successHandler" );
			if ( !$dbo )
			{
				// This seems to be the failure case, not the error handler
				Log.out( "LoadModelFromBigDB.successHandler - ERROR - NULL DatabaseObject for guid:" + _guid );
				finish();
				return;
			}

			var $ba:ByteArray = $dbo.data as ByteArray;
			if ( null == $ba ) {
				// This seems to be the failure case, not the error handler
				Log.out( "LoadModelFromBigDB.successHandler - ERROR - NULL data for guid:" + _guid );
				finish();
				return;
			}
			$ba.uncompress();
			$ba.position = 0;
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.fromPersistance( $dbo );
			
			var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( $ba, _guid, vmm );
			if ( vm ) {
				vm.complete = true;
				
				if ( vm is Player )
				{
					Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.PLAYER_LOAD_COMPLETE, _guid ) );
				}
				else {
					if ( vm.instanceInfo.critical )
						Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.CRITICAL_MODEL_LOADED, _guid ));
					else
						Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _guid ) );
				}
			}
			else 
				Log.out( "LoadModelFromBigDB.successHandler - FAILED loadFromManifestByteArray:" + _guid );

			
			finish();
		}
		
		private	function errorHandler(e:PlayerIOError):void	
		{ 
			Log.out( "LoadModelFromBigDB.errorHandler" );
			Log.out( "LoadModelFromBigDB.errorHandler - e: " + e );
			trace(e); 
			
			finish();
		}	
		
		private	function finish():void {
			_count--;				
			if ( 0 == _count )
			{
				Log.out( "LoadModelFromBigDB.successHandler - ALL MODELS LOADED - dispatching the LoadingEvent.LOAD_COMPLETE event vm: " + _guid );
				Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			}
				
			super.complete() // AbstractTask will send event
		}
		
	}
}
