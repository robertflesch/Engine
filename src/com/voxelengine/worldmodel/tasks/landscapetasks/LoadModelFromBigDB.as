/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import com.voxelengine.worldmodel.models.ModelLoader;
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
		private var _guid:String;
		protected var _startTime:int;
		
		public function LoadModelFromBigDB( $guid:String, $layer:LayerInfo = null ):void {
			//Log.out( "LoadModelFromBigDB.construct " );
			_guid = $guid
			_startTime = getTimer();
			super( _guid );
		}
		
		override public function start():void
		{
			//Log.out( "LoadModelFromBigDB.start" );
			var timer:int = getTimer();
			super.start() // AbstractTask will send event
			
			Persistance.loadObject( "voxelModels", _guid, successHandler, errorHandler );
		}
		
		private function successHandler($dbo:DatabaseObject):void 
		{ 
			if ( !$dbo )
			{
				// This seems to be the failure case, not the error handler
				Log.out( "LoadModelFromBigDB.successHandler - ERROR - NULL DatabaseObject for guid:" + _guid );
				super.complete() // AbstractTask will send event
				return;
			}

			var $ba:ByteArray = $dbo.data as ByteArray;
			$ba.uncompress();
			$ba.position = 0;
			
			var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( $ba, _guid );
			if ( vm ) {
				vm.databaseObject = $dbo;
				vm.complete = true;
			}
			else 
				Log.out( "LoadModelFromBigDB.successHandler - FAILED loadFromManifestByteArray:" + _guid );

			super.complete() // AbstractTask will send event
		}
		
		static private	function errorHandler(e:PlayerIOError):void	
		{ 
			Log.out( "LoadModelFromBigDB.errorHandler" );
			Log.out( "LoadModelFromBigDB.errorHandler - e: " + e );
			trace(e); 
		}	
	}
}
