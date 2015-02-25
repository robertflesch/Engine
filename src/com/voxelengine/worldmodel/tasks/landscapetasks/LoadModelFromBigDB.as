/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.landscapetasks
{
	import playerio.DatabaseObject;
	import playerio.PlayerIOError;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import com.developmentarc.core.tasks.tasks.AbstractTask;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.biomes.LayerInfo;

	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	import com.voxelengine.worldmodel.models.MetadataManager;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class LoadModelFromBigDB extends AbstractTask 
	{		
		static private var _count:int = 0;
		private var _guid:String;
		private var _startTime:int;
		private var _guidTemplate:String;
		private var _vmmBase:VoxelModelMetadata;
		
		public function LoadModelFromBigDB( $guid:String, $layer:LayerInfo = null ) {
			Log.out( "LoadModelFromBigDB.construct ", Log.ERROR );
			_guid = $guid
			_startTime = getTimer();
			//public function AbstractTask(type:String, priority:int = 5, uid:Object = null, selfOverride:Boolean = false, blocking:Boolean = false)
			super( _guid );
			_count++;
		}
		/*
		override public function start():void
		{
			//Log.out( "LoadModelFromBigDB.start for guid:" + _guid );
			var timer:int = getTimer();
			super.start() // AbstractTask will send event
			
			PersistModel.loadModel( _guid, successHandler, errorHandler );
		}
		
		private function successHandler($dbo:DatabaseObject):void 
		{ 
			Log.out( "LoadModelFromBigDB.successHandler base data loaded for guid:" + _guid, Log.DEBUG );
			if ( !$dbo )
			{
				// This seems to be the failure case, not the error handler
				Log.out( "LoadModelFromBigDB.successHandler - ERROR - NULL DatabaseObject for guid:" + _guid, Log.ERROR );
				finish( null );
				return;
			}

			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.fromPersistanceMetadata( $dbo );
			
			var vm:VoxelModel;
			// is this model using a template? if so them the model doesnt have oxel data itsself, 
			// but uses the oxel data from the template.
			if ( "" != vmm.templateGuid && null == vmm.data ) {
				// We have an object that is dependant on a template
				// is the template loaded, if not the templateManager will load the template
				// and inform us with a ModelMetadataEvent
				var tvmm:VoxelModelMetadata = MetadataManager.metadataGet( vmm.templateGuid );
				if ( tvmm ) {
					vm = ModelLoader.loadFromManifestByteArray( vmm, tvmm.data );
					finish( vm );
				}
				else {	
					// We need to hold onto this data with the template loades
					_guidTemplate = vmm.templateGuid;
					_vmmBase = vmm;
					ModelMetadataEvent.addListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, templateLoaded );
					ModelMetadataEvent.addListener( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, templateLoadFailed );
				}
			}
			else {
				// no template, just use the data from this record
				vm = ModelLoader.loadFromManifestByteArray( vmm, vmm.data );
				finish( vm );
			}
		}
		
		private	function errorHandler( $error:PlayerIOError ):void	
		{ 
			// Not sure when this error occurs, since if the database has no record, it succeeds but returns an empty record.
			Log.out( "LoadModelFromBigDB.failed to load base model - DB Server Down? error: " + $error.message, Log.ERROR, $error );
			finish( null);
		}	
		
		// all of the models and data have loaded ( or failed ). Send out the messages and clean up.
		private	function finish( $vm:VoxelModel ):void {
			
			if ( $vm ) {
				if ( $vm is Player )
				{
					LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.PLAYER_LOAD_COMPLETE, _guid ) );
				}
				else {
					if ( $vm.instanceInfo.critical )
						LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.CRITICAL_MODEL_LOADED, _guid ));
					else
						LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _guid ) );
				}
			}
			else 
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_FAILURE, _guid ) );
			
			_count--;				
			if ( 0 == _count )
			{
				Log.out( "LoadModelFromBigDB.finish - ALL MODELS LOADED - dispatching the LoadingEvent.LOAD_COMPLETE event vm: " + _guid, Log.DEBUG );
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			}
			else
				Log.out( "LoadModelFromBigDB.finish - MODEL LOADED - vm: " + _guid + "  this many left: " + _count, Log.DEBUG );
			
			
			_vmmBase = null;
			_guidTemplate = null;
				
			super.complete() // AbstractTask will send event
		}
		
		private function templateLoaded( $e:ModelMetadataEvent ):void {
			
			if ( _guidTemplate == $e.vmm.guid ) {
				ModelMetadataEvent.removeListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, templateLoaded );
				ModelMetadataEvent.removeListener( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, templateLoadFailed );
				// load the byte data from the template
				var vm:VoxelModel = ModelLoader.loadFromManifestByteArray( _vmmBase, $e.vmm.data );
				finish( vm );
			}
		}
		
		private function templateLoadFailed( $e:ModelMetadataEvent ):void {
			
			Log.out( "LoadModelFromBigDB.templateLoadFailed - guid: " + _guid, Log.ERROR );
			// The event data hold an emtpy voxelmodelMetadata object that only has the guid filled in,
			if ( _guidTemplate == $e.vmm.guid ) {
				ModelMetadataEvent.removeListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, templateLoaded );
				ModelMetadataEvent.removeListener( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, templateLoadFailed );
				finish( null );
			}
		}
		*/
	}
}
